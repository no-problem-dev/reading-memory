import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore, getStorage, getAuth } from '../config/firebase';
import { logger } from '../utils/logger';
import * as admin from 'firebase-admin';

interface DeleteResult {
  success: boolean;
  deletedCollections: string[];
  errors: string[];
}

export const deleteAccount = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user) {
      throw new ApiError(401, 'UNAUTHENTICATED', '認証が必要です。');
    }
    
    const uid = req.user.uid;
    const db = getFirestore();
    const storage = getStorage();
    const auth = getAuth();
    
    const result: DeleteResult = {
      success: false,
      deletedCollections: [],
      errors: [],
    };
    
    logger.info(`Starting account deletion for user: ${uid}`);
    
    // 1. Delete Firestore data
    const userCollections = [
      'userBooks',
      'goals',
      'activities',
      'achievements',
      'streaks',
    ];
    
    for (const collectionName of userCollections) {
      try {
        await deleteCollection(db, `users/${uid}/${collectionName}`, 500);
        result.deletedCollections.push(collectionName);
      } catch (error) {
        logger.error(`Error deleting ${collectionName}:`, error);
        result.errors.push(`Failed to delete ${collectionName}`);
      }
    }
    
    // Delete user document itself
    try {
      await db.doc(`users/${uid}`).delete();
      result.deletedCollections.push('users');
    } catch (error) {
      logger.error('Error deleting user document:', error);
      result.errors.push('Failed to delete user document');
    }
    
    // Delete profile document
    try {
      await db.doc(`userProfiles/${uid}`).delete();
      result.deletedCollections.push('userProfiles');
    } catch (error) {
      logger.error('Error deleting userProfile:', error);
      result.errors.push('Failed to delete userProfile');
    }
    
    // 2. Delete Cloud Storage data
    try {
      const bucket = storage.bucket();
      const [files] = await bucket.getFiles({
        prefix: `users/${uid}/`,
      });
      
      if (files.length > 0) {
        const deletePromises = files.map((file) => file.delete());
        await Promise.all(deletePromises);
        logger.info(`Deleted ${files.length} files from Storage`);
      }
    } catch (error) {
      logger.error('Error deleting Storage files:', error);
      result.errors.push('Failed to delete some Storage files');
    }
    
    // 3. Delete Firebase Auth account (last step)
    try {
      logger.info(`Attempting to delete auth account for user: ${uid}`);
      await auth.deleteUser(uid);
      logger.info(`Successfully deleted auth account for user: ${uid}`);
    } catch (error: any) {
      logger.error('Error deleting auth account:', {
        uid,
        error: error.message || error,
        code: error.code,
        stack: error.stack,
      });
      result.errors.push('Failed to delete authentication account');
      // Don't throw error here - return partial success/failure
    }
    
    result.success = result.errors.length === 0;
    
    // Log the final result
    logger.info(`Account deletion completed for user ${uid}`, {
      success: result.success,
      deletedCollections: result.deletedCollections,
      errors: result.errors,
    });
    
    res.json(result);
  } catch (error) {
    next(error);
  }
};

// Helper function to recursively delete collections
async function deleteCollection(
  db: admin.firestore.Firestore,
  collectionPath: string,
  batchSize: number
): Promise<void> {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.limit(batchSize);
  
  return new Promise((resolve, reject) => {
    deleteQueryBatch(db, query, resolve).catch(reject);
  });
}

async function deleteQueryBatch(
  db: admin.firestore.Firestore,
  query: admin.firestore.Query,
  resolve: () => void
): Promise<void> {
  try {
    const snapshot = await query.get();
    
    const batchSize = snapshot.size;
    if (batchSize === 0) {
      resolve();
      return;
    }
    
    const batch = db.batch();
    const deletePromises: Promise<void>[] = [];
    
    snapshot.docs.forEach((doc) => {
      // Handle subcollections for userBooks
      if (doc.ref.path.includes('/userBooks/')) {
        deletePromises.push(
          deleteCollection(db, `${doc.ref.path}/chats`, 500).catch((error) => {
            logger.error(`Error deleting chats for ${doc.ref.path}:`, error);
          })
        );
      }
      batch.delete(doc.ref);
    });
    
    // Wait for subcollection deletions
    await Promise.all(deletePromises);
    
    await batch.commit();
    
    // Delete next batch
    process.nextTick(() => {
      deleteQueryBatch(db, query, resolve).catch((error) => {
        logger.error('Error in deleteQueryBatch:', error);
        resolve(); // Resolve even on error to prevent hanging
      });
    });
  } catch (error) {
    logger.error('Error in deleteQueryBatch:', error);
    resolve(); // Resolve even on error to prevent hanging
  }
}