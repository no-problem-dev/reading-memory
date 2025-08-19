import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { ClaudeService } from '../services/claudeService';

interface GenerateAIResponseData {
  userId: string;
  userBookId: string;
  message: string;
}

export const generateAIResponse = functions
  .region('asia-northeast1')
  .runWith({
    timeoutSeconds: 60,
    memory: '512MB',
    secrets: ['CLAUDE_API_KEY']
  })
  .https.onCall(async (data: GenerateAIResponseData, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'ユーザーが認証されていません'
      );
    }
    
    // パラメータ検証
    const { userId, userBookId, message } = data;
    if (!userId || !userBookId || !message) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        '必須パラメータが不足しています'
      );
    }
    
    // ユーザーIDの一致を確認
    if (context.auth.uid !== userId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        '他のユーザーのデータにはアクセスできません'
      );
    }
    
    try {
      const db = admin.firestore();
      
      // UserBookの情報を取得
      const userBookDoc = await db
        .collection('users')
        .doc(userId)
        .collection('userBooks')
        .doc(userBookId)
        .get();
        
      if (!userBookDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          '本が見つかりません'
        );
      }
      
      const userBookData = userBookDoc.data()!;
      const bookTitle = userBookData.bookTitle || '不明な本';
      const bookAuthor = userBookData.bookAuthor || '不明な著者';
      
      // 過去のチャット履歴を取得（最新20件）
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
        .map(doc => {
          const data = doc.data();
          return {
            message: data.message,
            isAI: data.isAI || false
          };
        })
        .reverse(); // 時系列順に並び替え
      
      // Claude APIを使用して応答を生成
      const claudeService = new ClaudeService();
      const aiResponse = await claudeService.generateBookChatResponse(
        bookTitle,
        bookAuthor,
        previousChats,
        message
      );
      
      // AI応答をチャットに保存
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
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return {
        success: true,
        chatId: chatRef.id,
        message: aiResponse
      };
      
    } catch (error) {
      console.error('Error generating AI response:', error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
        'internal',
        'AI応答の生成中にエラーが発生しました'
      );
    }
  });