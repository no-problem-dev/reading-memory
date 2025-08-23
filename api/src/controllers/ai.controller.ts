import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore } from '../config/firebase';
import { ClaudeService } from '../services/claudeService';
import * as admin from 'firebase-admin';

export const generateAIResponse = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { bookId } = req.params;
    const { message } = req.body;
    
    const db = getFirestore();
    
    // Get book information
    const bookDoc = await db
      .collection('users')
      .doc(userId)
      .collection('books')
      .doc(bookId)
      .get();
    
    if (!bookDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', '本が見つかりません');
    }
    
    const bookData = bookDoc.data()!;
    const bookTitle = bookData.title || '不明な本';
    const bookAuthor = bookData.author || '不明な著者';
    
    // Get recent chat history
    const chatsSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('books')
      .doc(bookId)
      .collection('chats')
      .orderBy('createdAt', 'desc')
      .limit(20)
      .get();
    
    const previousChats = chatsSnapshot.docs
      .map((doc) => {
        const data = doc.data();
        return {
          message: data.message,
          isAI: data.messageType === 'ai',
        };
      })
      .reverse();
    
    // Generate AI response
    const claudeService = new ClaudeService();
    const aiResponse = await claudeService.generateBookChatResponse(
      bookTitle,
      bookAuthor,
      previousChats,
      message
    );
    
    // Save AI response to chat
    const chatRef = db
      .collection('users')
      .doc(userId)
      .collection('books')
      .doc(bookId)
      .collection('chats')
      .doc();
    
    await chatRef.set({
      message: aiResponse,
      messageType: 'ai',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    res.json({
      success: true,
      chatId: chatRef.id,
      message: aiResponse,
    });
  } catch (error) {
    next(error);
  }
};

export const generateBookSummary = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { bookId } = req.params;
    
    const db = getFirestore();
    
    // Get book information
    const bookDoc = await db
      .collection('users')
      .doc(userId)
      .collection('books')
      .doc(bookId)
      .get();
    
    if (!bookDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', '本が見つかりません');
    }
    
    const bookData = bookDoc.data()!;
    const bookTitle = bookData.title || '不明な本';
    const bookAuthor = bookData.author || '不明な著者';
    
    // Get all chat history
    const chatsSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('books')
      .doc(bookId)
      .collection('chats')
      .orderBy('createdAt', 'asc')
      .get();
    
    const chats = chatsSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        message: data.message,
        isAI: data.messageType === 'ai',
      };
    });
    
    if (chats.length === 0) {
      res.json({
        success: true,
        summary: 'まだ読書メモがありません。',
      });
      return;
    }
    
    // Generate summary
    const claudeService = new ClaudeService();
    const summary = await claudeService.generateBookSummary(
      bookTitle,
      bookAuthor,
      chats
    );
    
    // Save summary to book
    await db
      .collection('users')
      .doc(userId)
      .collection('books')
      .doc(bookId)
      .update({
        aiSummary: summary,
        summaryGeneratedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    
    res.json({
      success: true,
      summary: summary,
    });
  } catch (error) {
    next(error);
  }
};