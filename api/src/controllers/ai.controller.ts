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
    const { userId, userBookId } = req.params;
    const { message } = req.body;
    
    // Verify user authorization
    if (req.user?.uid !== userId) {
      throw new ApiError(403, 'PERMISSION_DENIED', '他のユーザーのデータにはアクセスできません');
    }
    
    const db = getFirestore();
    
    // Get UserBook information
    const userBookDoc = await db
      .collection('users')
      .doc(userId)
      .collection('userBooks')
      .doc(userBookId)
      .get();
    
    if (!userBookDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', '本が見つかりません');
    }
    
    const userBookData = userBookDoc.data()!;
    const bookTitle = userBookData.bookTitle || '不明な本';
    const bookAuthor = userBookData.bookAuthor || '不明な著者';
    
    // Get recent chat history
    const chatsSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('userBooks')
      .doc(userBookId)
      .collection('chats')
      .orderBy('createdAt', 'desc')
      .limit(20)
      .get();
    
    const previousChats = chatsSnapshot.docs
      .map((doc) => {
        const data = doc.data();
        return {
          message: data.message,
          isAI: data.isAI || false,
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
      .collection('userBooks')
      .doc(userBookId)
      .collection('chats')
      .doc();
    
    await chatRef.set({
      id: chatRef.id,
      userBookId: userBookId,
      userId: userId,
      message: aiResponse,
      isAI: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
    const { userId, userBookId } = req.params;
    
    // Verify user authorization
    if (req.user?.uid !== userId) {
      throw new ApiError(403, 'PERMISSION_DENIED', '他のユーザーのデータにはアクセスできません');
    }
    
    const db = getFirestore();
    
    // Get UserBook information
    const userBookDoc = await db
      .collection('users')
      .doc(userId)
      .collection('userBooks')
      .doc(userBookId)
      .get();
    
    if (!userBookDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', '本が見つかりません');
    }
    
    const userBookData = userBookDoc.data()!;
    const bookTitle = userBookData.bookTitle || '不明な本';
    const bookAuthor = userBookData.bookAuthor || '不明な著者';
    
    // Get all chat history
    const chatsSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('userBooks')
      .doc(userBookId)
      .collection('chats')
      .orderBy('createdAt', 'asc')
      .get();
    
    const chats = chatsSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        message: data.message,
        isAI: data.isAI || false,
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
    
    // Save summary to UserBook
    await db
      .collection('users')
      .doc(userId)
      .collection('userBooks')
      .doc(userBookId)
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