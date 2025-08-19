import * as admin from "firebase-admin";

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

async function createTestBooks() {
  const testBooks = [
    {
      isbn: "9784798121963",
      title: "リーダブルコード",
      author: "Dustin Boswell, Trevor Foucher",
      publisher: "オライリージャパン",
      publishedDate: new Date("2012-06-23"),
      pageCount: 260,
      description: "より良いコードを書くためのシンプルで実践的なテクニック",
      coverImageUrl: "https://books.google.com/books/content?id=Wx1dLwEACAAJ&printsec=frontcover&img=1&zoom=1",
      dataSource: "googleBooks",
      visibility: "public",
    },
    {
      isbn: "9784873117126",
      title: "プログラミング言語Go",
      author: "Alan A.A. Donovan, Brian W. Kernighan",
      publisher: "丸善出版",
      publishedDate: new Date("2016-06-20"),
      pageCount: 480,
      description: "Googleが開発したプログラミング言語Goの解説書",
      coverImageUrl: "https://books.google.com/books/content?id=B8tJjwEACAAJ&printsec=frontcover&img=1&zoom=1",
      dataSource: "googleBooks",
      visibility: "public",
    },
    {
      isbn: "9784774189093",
      title: "Webを支える技術",
      author: "山本 陽平",
      publisher: "技術評論社",
      publishedDate: new Date("2010-04-26"),
      pageCount: 400,
      description: "HTTP、URI、HTML、そしてREST",
      coverImageUrl: "https://books.google.com/books/content?id=jLTCjgEACAAJ&printsec=frontcover&img=1&zoom=1",
      dataSource: "openBD",
      visibility: "public",
    },
  ];

  console.log("Creating test books...");

  for (const bookData of testBooks) {
    try {
      // Check if book already exists
      const existingBook = await db
        .collection("books")
        .where("isbn", "==", bookData.isbn)
        .limit(1)
        .get();

      if (!existingBook.empty) {
        console.log(`Book with ISBN ${bookData.isbn} already exists. Skipping...`);
        continue;
      }

      // Create new book
      const docRef = await db.collection("books").add({
        ...bookData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Created book: ${bookData.title} (ID: ${docRef.id})`);
    } catch (error) {
      console.error(`Error creating book ${bookData.title}:`, error);
    }
  }

  console.log("Test data creation completed!");
}

// Run the script
createTestBooks()
  .then(() => {
    console.log("Script finished successfully");
    process.exit(0);
  })
  .catch((error) => {
    console.error("Script failed:", error);
    process.exit(1);
  });