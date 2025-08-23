import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { BookSearchService } from '../services/bookSearchService';
import { config } from '../config';
import { getFirestore } from '../config/firebase';
import { FieldValue, Query } from 'firebase-admin/firestore';

// Search endpoints (existing)
export const searchBookByISBN = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { isbn } = req.params;
    
    // Normalize ISBN (remove hyphens)
    const normalizedISBN = isbn.replace(/-/g, '');
    
    // Validate ISBN-10 or ISBN-13
    if (!/^(978|979)?\d{9}[\dX]$/.test(normalizedISBN)) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'ISBNの形式が正しくありません。');
    }
    
    const searchService = new BookSearchService(config.googleBooksApiKey);
    const results = await searchService.searchByISBN(normalizedISBN);
    
    if (results.length === 0) {
      throw new ApiError(404, 'NOT_FOUND', '該当する書籍が見つかりませんでした。');
    }
    
    res.json({
      books: results,
    });
  } catch (error) {
    next(error);
  }
};

export const searchBooksByQuery = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const query = req.query.q as string;
    
    const searchService = new BookSearchService(config.googleBooksApiKey);
    const results = await searchService.searchByQuery(query);
    
    res.json({
      books: results,
    });
  } catch (error) {
    next(error);
  }
};

// CRUD endpoints (new)
export const getBooks = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { status, limit = 20, startAfter } = req.query;
    
    const db = getFirestore();
    let query: Query = db.collection('users').doc(userId).collection('books');
    
    // Filter by status if provided
    if (status) {
      query = query.where('status', '==', status);
    }
    
    // Order by addedDate descending
    query = query.orderBy('addedDate', 'desc');
    
    // Pagination
    if (limit) {
      query = query.limit(Number(limit));
    }
    
    if (startAfter) {
      const lastDoc = await db.collection('users').doc(userId).collection('books').doc(String(startAfter)).get();
      if (lastDoc.exists) {
        query = query.startAfter(lastDoc);
      }
    }
    
    const snapshot = await query.get();
    const books = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.json({ books });
  } catch (error) {
    next(error);
  }
};

export const getBook = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { bookId } = req.params;
    
    const db = getFirestore();
    const doc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    res.json({
      id: doc.id,
      ...doc.data()
    });
  } catch (error) {
    next(error);
  }
};

export const createBook = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const bookData = req.body;
    
    // Remove userId from bookData if it exists
    delete bookData.userId;
    delete bookData.id;
    
    // Add server timestamps
    const data = {
      ...bookData,
      userId, // Add userId on server side
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      addedDate: bookData.addedDate || FieldValue.serverTimestamp()
    };
    
    const db = getFirestore();
    const docRef = await db.collection('users').doc(userId).collection('books').add(data);
    const doc = await docRef.get();
    
    res.status(201).json({
      id: doc.id,
      ...doc.data()
    });
  } catch (error) {
    next(error);
  }
};

export const updateBook = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { bookId } = req.params;
    const updates = req.body;
    
    // Remove fields that shouldn't be updated
    delete updates.id;
    delete updates.userId;
    delete updates.createdAt;
    
    // Add updated timestamp
    updates.updatedAt = FieldValue.serverTimestamp();
    
    const db = getFirestore();
    const bookRef = db.collection('users').doc(userId).collection('books').doc(bookId);
    const doc = await bookRef.get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    await bookRef.update(updates);
    const updatedDoc = await bookRef.get();
    
    res.json({
      id: updatedDoc.id,
      ...updatedDoc.data()
    });
  } catch (error) {
    next(error);
  }
};

export const deleteBook = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { bookId } = req.params;
    
    const db = getFirestore();
    const bookRef = db.collection('users').doc(userId).collection('books').doc(bookId);
    const doc = await bookRef.get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    // Delete all chats for this book
    const chatsSnapshot = await bookRef.collection('chats').get();
    const deletePromises = chatsSnapshot.docs.map((chat: any) => chat.ref.delete());
    await Promise.all(deletePromises);
    
    // Delete the book
    await bookRef.delete();
    
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

// Get books by status (convenience endpoints)
export const getWantToReadBooks = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  req.query.status = 'want_to_read';
  return getBooks(req, res, next);
};

export const getReadingBooks = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  req.query.status = 'reading';
  return getBooks(req, res, next);
};

export const getCompletedBooks = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  req.query.status = 'completed';
  return getBooks(req, res, next);
};