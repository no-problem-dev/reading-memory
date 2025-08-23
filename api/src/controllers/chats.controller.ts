import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore } from '../config/firebase';
import { FieldValue, Query } from 'firebase-admin/firestore';
import { serializeTimestamps } from '../utils/timestamp';

export const getChats = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const db = getFirestore();
    const userId = req.user!.uid;
    const { bookId } = req.params;
    const { limit = 50, startAfter } = req.query;
    
    // Check if book exists
    const bookDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    if (!bookDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    let query: Query = db.collection('users').doc(userId).collection('books').doc(bookId).collection('chats');
    
    // Order by createdAt ascending (oldest first)
    query = query.orderBy('createdAt', 'asc');
    
    // Pagination
    if (limit) {
      query = query.limit(Number(limit));
    }
    
    if (startAfter) {
      const lastDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).collection('chats').doc(String(startAfter)).get();
      if (lastDoc.exists) {
        query = query.startAfter(lastDoc);
      }
    }
    
    const snapshot = await query.get();
    const chats = snapshot.docs.map(doc => serializeTimestamps({
      id: doc.id,
      ...doc.data()
    }));
    
    res.json({ chats });
  } catch (error) {
    next(error);
  }
};

// Create a new chat
export const createChat = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const db = getFirestore();
    const userId = req.user!.uid;
    const { bookId } = req.params;
    const { message, messageType = 'user' } = req.body;
    
    if (!message || message.trim().length === 0) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Message cannot be empty');
    }
    
    // Check if book exists
    const bookDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    if (!bookDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    // Create chat data
    const chatData = {
      message: message.trim(),
      messageType,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    };
    
    const docRef = await db.collection('users').doc(userId).collection('books').doc(bookId).collection('chats').add(chatData);
    const doc = await docRef.get();
    
    res.status(201).json({
      chat: serializeTimestamps({
        id: doc.id,
        ...doc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Update a chat
export const updateChat = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const db = getFirestore();
    const userId = req.user!.uid;
    const { bookId, chatId } = req.params;
    const { message } = req.body;
    
    if (!message || message.trim().length === 0) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Message cannot be empty');
    }
    
    const chatRef = db.collection('users').doc(userId).collection('books').doc(bookId).collection('chats').doc(chatId);
    const doc = await chatRef.get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Chat not found');
    }
    
    const updates = {
      message: message.trim(),
      updatedAt: FieldValue.serverTimestamp()
    };
    
    await chatRef.update(updates);
    const updatedDoc = await chatRef.get();
    
    res.json({
      chat: serializeTimestamps({
        id: updatedDoc.id,
        ...updatedDoc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Delete a chat
export const deleteChat = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const db = getFirestore();
    const userId = req.user!.uid;
    const { bookId, chatId } = req.params;
    
    const chatRef = db.collection('users').doc(userId).collection('books').doc(bookId).collection('chats').doc(chatId);
    const doc = await chatRef.get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Chat not found');
    }
    
    await chatRef.delete();
    
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};