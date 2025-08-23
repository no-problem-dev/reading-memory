import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { getFirestore } from '../config/firebase';

export const getPopularBooks = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const limit = parseInt(req.query.limit as string || '20', 10);
    
    const db = getFirestore();
    
    // Get public books (currently ordered by creation date, will be sorted by user count in the future)
    const booksSnapshot = await db
      .collection('books')
      .where('visibility', '==', 'public')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();
    
    const books = booksSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    res.json({ books });
  } catch (error) {
    next(error);
  }
};

export const getRecentBooks = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const limit = parseInt(req.query.limit as string || '20', 10);
    
    const db = getFirestore();
    
    const booksSnapshot = await db
      .collection('books')
      .where('visibility', '==', 'public')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();
    
    const books = booksSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    res.json({ books });
  } catch (error) {
    next(error);
  }
};

export const searchPublicBooks = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const query = req.query.q as string;
    const limit = parseInt(req.query.limit as string || '20', 10);
    
    const db = getFirestore();
    const lowercaseQuery = query.toLowerCase();
    
    // Search by title
    const titleSnapshot = await db
      .collection('books')
      .where('visibility', '==', 'public')
      .orderBy('title')
      .startAt(lowercaseQuery)
      .endAt(lowercaseQuery + '\uf8ff')
      .limit(limit)
      .get();
    
    const books = new Map<string, any>();
    
    // Add title search results
    titleSnapshot.docs.forEach((doc) => {
      books.set(doc.id, {
        id: doc.id,
        ...doc.data(),
      });
    });
    
    // Search by author if we have remaining slots
    if (books.size < limit) {
      const remainingLimit = limit - books.size;
      const authorSnapshot = await db
        .collection('books')
        .where('visibility', '==', 'public')
        .orderBy('author')
        .startAt(lowercaseQuery)
        .endAt(lowercaseQuery + '\uf8ff')
        .limit(remainingLimit)
        .get();
      
      authorSnapshot.docs.forEach((doc) => {
        if (!books.has(doc.id)) {
          books.set(doc.id, {
            id: doc.id,
            ...doc.data(),
          });
        }
      });
    }
    
    res.json({
      books: Array.from(books.values()),
    });
  } catch (error) {
    next(error);
  }
};