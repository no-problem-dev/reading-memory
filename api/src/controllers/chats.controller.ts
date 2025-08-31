import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore } from '../config/firebase';
import { FieldValue, Query } from 'firebase-admin/firestore';
import { serializeTimestamps } from '../utils/timestamp';
import { Chat, ChatResponse, ChatsResponse } from '../types/chat';

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
    const chats: Chat[] = snapshot.docs.map(doc => serializeTimestamps({
      id: doc.id,
      ...doc.data()
    }) as Chat);
    
    const response: ChatsResponse = { chats };
    res.json(response);
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
    const { message, messageType = 'user', imageId, chapterOrSection, pageNumber } = req.body;
    
    if (!message || message.trim().length === 0) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Message cannot be empty');
    }
    
    // Check if book exists
    const bookDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    if (!bookDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    // If imageId is provided, verify it exists and belongs to the user
    if (imageId) {
      const imageDoc = await db.collection('images').doc(imageId).get();
      if (!imageDoc.exists) {
        throw new ApiError(404, 'NOT_FOUND', 'Image not found');
      }
      const imageData = imageDoc.data();
      if (imageData?.uploadedBy !== userId) {
        throw new ApiError(403, 'FORBIDDEN', 'You do not have access to this image');
      }
    }
    
    // Create chat data
    const chatData: any = {
      message: message.trim(),
      messageType,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    };
    
    // Add optional fields if provided
    if (imageId) {
      chatData.imageId = imageId;
    }
    
    if (chapterOrSection) {
      chatData.chapterOrSection = chapterOrSection;
    }
    
    if (pageNumber !== undefined && pageNumber !== null) {
      chatData.pageNumber = pageNumber;
    }
    
    const docRef = await db.collection('users').doc(userId).collection('books').doc(bookId).collection('chats').add(chatData);
    const doc = await docRef.get();
    
    const chat: Chat = serializeTimestamps({
      id: doc.id,
      ...doc.data()
    }) as Chat;
    
    const response: ChatResponse = { chat };
    res.status(201).json(response);
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
    const { message, chapterOrSection, pageNumber } = req.body;
    
    if (!message || message.trim().length === 0) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Message cannot be empty');
    }
    
    const chatRef = db.collection('users').doc(userId).collection('books').doc(bookId).collection('chats').doc(chatId);
    const doc = await chatRef.get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Chat not found');
    }
    
    const updates: any = {
      message: message.trim(),
      updatedAt: FieldValue.serverTimestamp()
    };
    
    // Add optional fields if provided
    if (chapterOrSection !== undefined) {
      updates.chapterOrSection = chapterOrSection;
    }
    
    if (pageNumber !== undefined && pageNumber !== null) {
      updates.pageNumber = pageNumber;
    }
    
    await chatRef.update(updates);
    const updatedDoc = await chatRef.get();
    
    const chat: Chat = serializeTimestamps({
      id: updatedDoc.id,
      ...updatedDoc.data()
    }) as Chat;
    
    const response: ChatResponse = { chat };
    res.json(response);
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