import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { ClaudeService } from '../services/claudeService';

interface GenerateBookSummaryData {
  userId: string;
  userBookId: string;
}

export const generateBookSummary = functions
  .region('asia-northeast1')
  .runWith({
    timeoutSeconds: 60,
    memory: '512MB',
    secrets: ['CLAUDE_API_KEY']
  })
  .https.onCall(async (data: GenerateBookSummaryData, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'ユーザーが認証されていません'
      );
    }
    
    // パラメータ検証
    const { userId, userBookId } = data;
    if (!userId || !userBookId) {
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
      
      // すべてのチャット履歴を取得
      const chatsSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('userBooks')
        .doc(userBookId)
        .collection('chats')
        .orderBy('createdAt', 'asc')
        .get();
        
      const chats = chatsSnapshot.docs.map(doc => {
        const data = doc.data();
        return {
          message: data.message,
          isAI: data.isAI || false
        };
      });
      
      if (chats.length === 0) {
        return {
          success: true,
          summary: 'まだ読書メモがありません。'
        };
      }
      
      // Claude APIを使用して要約を生成
      const claudeService = new ClaudeService();
      const summary = await claudeService.generateBookSummary(
        bookTitle,
        bookAuthor,
        chats
      );
      
      // 要約をUserBookに保存
      await db
        .collection('users')
        .doc(userId)
        .collection('userBooks')
        .doc(userBookId)
        .update({
          aiSummary: summary,
          summaryGeneratedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      
      return {
        success: true,
        summary: summary
      };
      
    } catch (error) {
      console.error('Error generating book summary:', error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
        'internal',
        '要約の生成中にエラーが発生しました'
      );
    }
  });