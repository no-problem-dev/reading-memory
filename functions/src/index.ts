import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { BookSearchService } from "./services/bookSearchService";

admin.initializeApp();

// 書籍検索 - ISBNベース
export const searchBookByISBN = functions
  .region("asia-northeast1")
  .runWith({
    secrets: ["GOOGLE_BOOKS_API_KEY"],
  })
  .https.onCall(async (data: { isbn: string }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です。"
      );
    }

    const { isbn } = data;

    if (!isbn || typeof isbn !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "ISBNが正しく指定されていません。"
      );
    }

    // ISBNの正規化（ハイフンを除去）
    const normalizedISBN = isbn.replace(/-/g, "");

    // ISBN-10またはISBN-13の検証
    if (!/^(978|979)?\d{9}[\dX]$/.test(normalizedISBN)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "ISBNの形式が正しくありません。"
      );
    }

    try {
      const apiKey = process.env.GOOGLE_BOOKS_API_KEY || "";
      const searchService = new BookSearchService(apiKey);
      const results = await searchService.searchByISBN(normalizedISBN);

      if (results.length === 0) {
        throw new functions.https.HttpsError(
          "not-found",
          "該当する書籍が見つかりませんでした。"
        );
      }

      return {
        books: results,
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      console.error("Book search error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "書籍情報の取得に失敗しました。"
      );
    }
  });

// 書籍検索 - キーワードベース
export const searchBooksByQuery = functions
  .region("asia-northeast1")
  .runWith({
    secrets: ["GOOGLE_BOOKS_API_KEY"],
  })
  .https.onCall(async (data: { query: string }, context) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です。"
      );
    }

    const { query } = data;

    if (!query || typeof query !== "string" || query.trim().length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "検索クエリが正しく指定されていません。"
      );
    }

    try {
      const apiKey = process.env.GOOGLE_BOOKS_API_KEY || "";
      const searchService = new BookSearchService(apiKey);
      const results = await searchService.searchByQuery(query);

      return {
        books: results,
      };
    } catch (error) {
      console.error("Book search error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "書籍検索に失敗しました。"
      );
    }
  });

// 公開本の人気ランキング取得
export const getPopularBooks = functions
  .region("asia-northeast1")
  .https.onCall(async (data: { limit?: number }, context) => {
    const limit = data.limit || 20;

    try {
      // 公開本を取得（現在は作成日順、将来的には登録ユーザー数でソート）
      const booksSnapshot = await admin
        .firestore()
        .collection("books")
        .where("visibility", "==", "public")
        .orderBy("createdAt", "desc")
        .limit(limit)
        .get();

      const books = booksSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      return { books };
    } catch (error) {
      console.error("Get popular books error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "人気の本の取得に失敗しました。"
      );
    }
  });

// 公開本の新着取得
export const getRecentBooks = functions
  .region("asia-northeast1")
  .https.onCall(async (data: { limit?: number }, context) => {
    const limit = data.limit || 20;

    try {
      const booksSnapshot = await admin
        .firestore()
        .collection("books")
        .where("visibility", "==", "public")
        .orderBy("createdAt", "desc")
        .limit(limit)
        .get();

      const books = booksSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      return { books };
    } catch (error) {
      console.error("Get recent books error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "新着の本の取得に失敗しました。"
      );
    }
  });

// 公開本の検索
export const searchPublicBooks = functions
  .region("asia-northeast1")
  .https.onCall(async (data: { query: string; limit?: number }, context) => {
    const { query } = data;
    const limit = data.limit || 20;

    if (!query || typeof query !== "string" || query.trim().length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "検索クエリが正しく指定されていません。"
      );
    }

    try {
      const lowercaseQuery = query.toLowerCase();

      // タイトルで検索
      const titleSnapshot = await admin
        .firestore()
        .collection("books")
        .where("visibility", "==", "public")
        .orderBy("title")
        .startAt(lowercaseQuery)
        .endAt(lowercaseQuery + "\uf8ff")
        .limit(limit)
        .get();

      const books = new Map<string, any>();

      // タイトル検索結果を追加
      titleSnapshot.docs.forEach((doc) => {
        books.set(doc.id, {
          id: doc.id,
          ...doc.data(),
        });
      });

      // 残りの枠で著者検索
      if (books.size < limit) {
        const remainingLimit = limit - books.size;
        const authorSnapshot = await admin
          .firestore()
          .collection("books")
          .where("visibility", "==", "public")
          .orderBy("author")
          .startAt(lowercaseQuery)
          .endAt(lowercaseQuery + "\uf8ff")
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

      return {
        books: Array.from(books.values()),
      };
    } catch (error) {
      console.error("Search public books error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "公開本の検索に失敗しました。"
      );
    }
  });