import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore, getStorage, getAuth } from '../config/firebase';
import { logger } from '../utils/logger';
import * as admin from 'firebase-admin';
import { serializeTimestamps } from '../utils/timestamp';

interface DeleteResult {
  success: boolean;
  deletedCollections: string[];
  errors: string[];
}

interface UserProfile {
  id: string;
  displayName: string;
  avatarImageId?: string;
  bio?: string;
  favoriteGenres: string[];
  readingGoal?: number;
  isPublic: boolean;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
}

export const getProfile = async (
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
    
    const profileDoc = await db.doc(`userProfiles/${uid}`).get();
    
    if (!profileDoc.exists) {
      res.status(404).json({
        error: {
          code: 'NOT_FOUND',
          message: 'Profile not found',
        },
      });
      return;
    }
    
    const profile = profileDoc.data() as UserProfile;
    res.json({
      profile: serializeTimestamps(profile)
    });
  } catch (error) {
    next(error);
  }
};

export const createProfile = async (
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
    
    // Check if profile already exists
    const existingProfile = await db.doc(`userProfiles/${uid}`).get();
    if (existingProfile.exists) {
      throw new ApiError(409, 'ALREADY_EXISTS', 'Profile already exists');
    }
    
    const now = admin.firestore.Timestamp.now();
    const profile: UserProfile = {
      id: uid,
      displayName: req.body.displayName || '',
      favoriteGenres: req.body.favoriteGenres || [],
      isPublic: req.body.isPublic ?? false,
      createdAt: now,
      updatedAt: now,
    };
    
    // Optional fields - only add if not undefined
    if (req.body.avatarImageId !== undefined) {
      profile.avatarImageId = req.body.avatarImageId;
    }
    if (req.body.bio !== undefined) {
      profile.bio = req.body.bio;
    }
    if (req.body.readingGoal !== undefined) {
      profile.readingGoal = req.body.readingGoal;
    }
    
    await db.doc(`userProfiles/${uid}`).set(profile);
    
    res.status(201).json({
      profile: serializeTimestamps(profile)
    });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (
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
    
    const profileRef = db.doc(`userProfiles/${uid}`);
    const profileDoc = await profileRef.get();
    
    if (!profileDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Profile not found');
    }
    
    const updates: Partial<UserProfile> = {
      updatedAt: admin.firestore.Timestamp.now(),
    };
    
    if (req.body.displayName !== undefined) {
      updates.displayName = req.body.displayName;
    }
    if (req.body.avatarImageId !== undefined) {
      updates.avatarImageId = req.body.avatarImageId;
    }
    if (req.body.bio !== undefined) {
      updates.bio = req.body.bio;
    }
    if (req.body.favoriteGenres !== undefined) {
      updates.favoriteGenres = req.body.favoriteGenres;
    }
    if (req.body.readingGoal !== undefined) {
      updates.readingGoal = req.body.readingGoal;
    }
    if (req.body.isPublic !== undefined) {
      updates.isPublic = req.body.isPublic;
    }
    
    await profileRef.update(updates);
    
    const updatedProfile = await profileRef.get();
    const data = updatedProfile.data() as UserProfile;
    
    res.json({
      profile: serializeTimestamps(data)
    });
  } catch (error) {
    next(error);
  }
};

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
    
    // 2. Delete user's images from images collection
    try {
      const imagesQuery = db.collection('images').where('uploadedBy', '==', uid);
      const imagesSnapshot = await imagesQuery.get();
      
      if (!imagesSnapshot.empty) {
        const batch = db.batch();
        const bucket = storage.bucket();
        
        for (const doc of imagesSnapshot.docs) {
          const imageData = doc.data();
          // Delete from Storage
          try {
            await bucket.file(imageData.storagePath).delete();
          } catch (error) {
            logger.warn(`Failed to delete image file: ${imageData.storagePath}`, error);
          }
          // Delete from Firestore
          batch.delete(doc.ref);
        }
        
        await batch.commit();
        logger.info(`Deleted ${imagesSnapshot.size} images for user ${uid}`);
        result.deletedCollections.push('images');
      }
    } catch (error) {
      logger.error('Error deleting user images:', error);
      result.errors.push('Failed to delete user images');
    }
    
    // 3. Note: Firebase Auth account deletion is now handled client-side
    // The server-side deletion often fails due to permission restrictions
    // when using Admin SDK to delete another user's account.
    // Client-side deletion is more reliable as the user is deleting their own account.
    logger.info(`Skipping server-side auth deletion for user ${uid}, will be handled client-side`);
    
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