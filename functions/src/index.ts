import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

interface OpenBDBook {
  onix: {
    DescriptiveDetail?: {
      TitleDetail?: {
        TitleElement?: Array<{
          TitleText?: string;
        }>;
      };
      Contributor?: Array<{
        PersonName?: string;
        BiographicalNote?: string;
      }>;
      Extent?: Array<{
        ExtentType?: string;
        ExtentValue?: string;
      }>;
    };
    CollateralDetail?: {
      TextContent?: Array<{
        Text?: string;
        TextType?: string;
      }>;
    };
    PublishingDetail?: {
      Imprint?: {
        ImprintName?: string;
      };
      PublishingDate?: Array<{
        Date?: string;
        DateFormat?: string;
      }>;
    };
  };
  summary: {
    isbn?: string;
    title?: string;
    author?: string;
    publisher?: string;
    pubdate?: string;
    cover?: string;
  };
}

interface BookInfo {
  isbn: string;
  title: string;
  author: string;
  publisher?: string;
  publishedDate?: string;
  pageCount?: number;
  description?: string;
  coverUrl?: string;
}

export const searchBookByISBN = functions
  .region("asia-northeast1")
  .https.onCall(async (data: {isbn: string}, context: functions.https.CallableContext) => {
    // 認証チェック
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "認証が必要です。"
      );
    }

    const {isbn} = data;

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
      // OpenBD APIを呼び出し
      const response = await axios.get<OpenBDBook[]>(
        `https://api.openbd.jp/v1/get?isbn=${normalizedISBN}`
      );

      if (!response.data || response.data.length === 0 || !response.data[0]) {
        throw new functions.https.HttpsError(
          "not-found",
          "該当する書籍が見つかりませんでした。"
        );
      }

      const bookData = response.data[0];
      const bookInfo = extractBookInfo(bookData);

      // Firestoreにマスターデータとして保存
      const booksRef = admin.firestore().collection("books");
      const existingBook = await booksRef
        .where("isbn", "==", normalizedISBN)
        .limit(1)
        .get();

      let bookId: string;

      if (existingBook.empty) {
        // 新規登録
        const newBookRef = await booksRef.add({
          ...bookInfo,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        bookId = newBookRef.id;
      } else {
        // 既存データを更新
        bookId = existingBook.docs[0].id;
        await booksRef.doc(bookId).update({
          ...bookInfo,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return {
        bookId,
        ...bookInfo,
      };
    } catch (error) {
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      console.error("OpenBD API error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "書籍情報の取得に失敗しました。"
      );
    }
  });

function extractBookInfo(bookData: OpenBDBook): BookInfo {
  const summary = bookData.summary || {};
  const onix = bookData.onix || {};
  const descriptive = onix.DescriptiveDetail || {};
  const publishing = onix.PublishingDetail || {};
  const collateral = onix.CollateralDetail || {};

  // タイトル
  let title = summary.title || "";
  if (!title && descriptive.TitleDetail?.TitleElement?.[0]?.TitleText) {
    title = descriptive.TitleDetail.TitleElement[0].TitleText;
  }

  // 著者
  let author = summary.author || "";
  if (!author && descriptive.Contributor?.[0]?.PersonName) {
    author = descriptive.Contributor.map((c) => c.PersonName).join(", ");
  }

  // 出版社
  let publisher = summary.publisher || "";
  if (!publisher && publishing.Imprint?.ImprintName) {
    publisher = publishing.Imprint.ImprintName;
  }

  // 出版日
  let publishedDate = summary.pubdate || "";
  if (!publishedDate && publishing.PublishingDate?.[0]?.Date) {
    const date = publishing.PublishingDate[0].Date;
    // YYYYMMDD形式をYYYY-MM-DD形式に変換
    if (date.length === 8) {
      publishedDate = `${date.slice(0, 4)}-${date.slice(4, 6)}-${date.slice(6, 8)}`;
    }
  }

  // ページ数
  let pageCount: number | undefined;
  const extents = descriptive.Extent || [];
  for (const extent of extents) {
    if (extent.ExtentType === "11" && extent.ExtentValue) {
      pageCount = parseInt(extent.ExtentValue, 10);
      break;
    }
  }

  // 説明
  let description = "";
  const textContents = collateral.TextContent || [];
  for (const content of textContents) {
    if (content.TextType === "03" && content.Text) {
      description = content.Text;
      break;
    }
  }

  // カバー画像
  const coverUrl = summary.cover || undefined;

  return {
    isbn: summary.isbn || "",
    title,
    author,
    publisher: publisher || undefined,
    publishedDate: publishedDate || undefined,
    pageCount,
    description: description || undefined,
    coverUrl,
  };
}