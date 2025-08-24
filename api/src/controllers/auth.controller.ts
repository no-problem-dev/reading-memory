import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore } from '../config/firebase';
import { logger } from '../utils/logger';
import * as admin from 'firebase-admin';

interface UserInitResult {
  initialized: boolean;
  hasProfile: boolean;
  message: string;
}

export const initializeUser = async (
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
    
    // Check if user document exists
    const userDoc = await db.doc(`users/${uid}`).get();
    
    if (!userDoc.exists) {
      // Create user document
      const now = admin.firestore.Timestamp.now();
      await db.doc(`users/${uid}`).set({
        id: uid,
        email: req.user.email || '',
        createdAt: now,
        updatedAt: now,
      });
      
      logger.info(`Created user document for ${uid}`);
    }
    
    // Check if profile exists
    const profileDoc = await db.doc(`userProfiles/${uid}`).get();
    const hasProfile = profileDoc.exists;
    
    const result: UserInitResult = {
      initialized: true,
      hasProfile,
      message: hasProfile ? 'User initialized with profile' : 'User initialized, needs onboarding',
    };
    
    res.json(result);
  } catch (error) {
    next(error);
  }
};

export const getOnboardingStatus = async (
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
    
    // Check multiple conditions for onboarding completion
    const [profileDoc, goalsSnapshot] = await Promise.all([
      db.doc(`userProfiles/${uid}`).get(),
      db.collection(`users/${uid}/goals`).limit(1).get(),
    ]);
    
    const hasProfile = profileDoc.exists;
    const hasGoals = !goalsSnapshot.empty;
    
    // User needs onboarding if they don't have a profile
    const needsOnboarding = !hasProfile;
    
    res.json({
      needsOnboarding,
      hasProfile,
      hasGoals,
    });
  } catch (error) {
    next(error);
  }
};

export const completeOnboarding = async (
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
    
    // Validate required fields
    const { displayName, favoriteGenres, monthlyGoal } = req.body;
    
    if (!displayName || !displayName.trim()) {
      throw new ApiError(400, 'INVALID_ARGUMENT', '表示名は必須です。');
    }
    
    if (!Array.isArray(favoriteGenres)) {
      throw new ApiError(400, 'INVALID_ARGUMENT', '好きなジャンルは配列で指定してください。');
    }
    
    if (typeof monthlyGoal !== 'number' || monthlyGoal < 0) {
      throw new ApiError(400, 'INVALID_ARGUMENT', '月間目標は0以上の数値で指定してください。');
    }
    
    const now = admin.firestore.Timestamp.now();
    
    // Start a batch write
    const batch = db.batch();
    
    // 1. Create or update user profile
    const profileData = {
      id: uid,
      displayName: displayName.trim(),
      avatarImageId: req.body.avatarImageId || null,
      bio: req.body.bio || null,
      favoriteGenres,
      readingGoal: monthlyGoal,
      isPublic: false,
      createdAt: now,
      updatedAt: now,
    };
    
    // Remove undefined/null fields for Firestore
    const cleanProfileData: any = {};
    Object.entries(profileData).forEach(([key, value]) => {
      if (value !== undefined) {
        cleanProfileData[key] = value;
      }
    });
    
    batch.set(db.doc(`userProfiles/${uid}`), cleanProfileData, { merge: true });
    
    // 2. Create initial monthly goal
    if (monthlyGoal > 0) {
      const currentDate = new Date();
      const startDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1);
      const endDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0, 23, 59, 59, 999);
      
      const goalData = {
        id: db.collection(`users/${uid}/goals`).doc().id,
        type: 'monthly',
        targetBooks: monthlyGoal,
        currentBooks: 0,
        startDate: admin.firestore.Timestamp.fromDate(startDate),
        endDate: admin.firestore.Timestamp.fromDate(endDate),
        isAchieved: false,
        createdAt: now,
        updatedAt: now,
      };
      
      batch.set(db.doc(`users/${uid}/goals/${goalData.id}`), goalData);
    }
    
    // 3. Initialize reading streak
    const streakData = {
      id: db.collection(`users/${uid}/streaks`).doc().id,
      currentStreak: 0,
      longestStreak: 0,
      lastReadDate: null,
      streakStartDate: null,
      createdAt: now,
      updatedAt: now,
    };
    
    batch.set(db.doc(`users/${uid}/streaks/${streakData.id}`), streakData);
    
    // Commit the batch
    await batch.commit();
    
    logger.info(`Completed onboarding for user ${uid}`);
    
    res.json({
      success: true,
      message: 'Onboarding completed successfully',
    });
  } catch (error) {
    next(error);
  }
};