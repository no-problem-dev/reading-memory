import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore } from '../config/firebase';
import { FieldValue, Query } from 'firebase-admin/firestore';
import { serializeTimestamps } from '../utils/timestamp';

// Get all streaks
export const getStreaks = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { type } = req.query;
    
    const db = getFirestore();
    let query: Query = db.collection('users').doc(userId).collection('streaks');
    
    if (type) {
      query = query.where('type', '==', type);
    }
    
    const snapshot = await query.get();
    const streaks = snapshot.docs.map(doc => serializeTimestamps({
      id: doc.id,
      ...doc.data()
    }));
    
    res.json({ streaks });
  } catch (error) {
    next(error);
  }
};

// Get a specific streak
export const getStreak = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { streakId } = req.params;
    
    const db = getFirestore();
    const doc = await db.collection('users').doc(userId).collection('streaks').doc(streakId).get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Streak not found');
    }
    
    res.json({
      streak: serializeTimestamps({
        id: doc.id,
        ...doc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Get streak by type
export const getStreakByType = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { type } = req.params;
    
    if (!['reading', 'chatMemo', 'combined'].includes(type)) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Invalid streak type');
    }
    
    const db = getFirestore();
    const snapshot = await db.collection('users').doc(userId).collection('streaks')
      .where('type', '==', type)
      .limit(1)
      .get();
    
    if (snapshot.empty) {
      // Return empty streak
      res.json({
        id: null,
        userId,
        type,
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
        streakDates: []
      });
    } else {
      const doc = snapshot.docs[0];
      res.json(serializeTimestamps({
        id: doc.id,
        ...doc.data()
      }));
    }
  } catch (error) {
    next(error);
  }
};

// Record activity and update streak
export const recordActivity = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { type, date } = req.body;
    
    if (!type || !['reading', 'chatMemo', 'combined'].includes(type)) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Invalid streak type');
    }
    
    const activityDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(activityDate);
    startOfDay.setHours(0, 0, 0, 0);
    
    const db = getFirestore();
    
    // Find existing streak or create new one
    const streaksQuery = await db.collection('users').doc(userId).collection('streaks')
      .where('type', '==', type)
      .limit(1)
      .get();
    
    let streakRef;
    let currentData: any = null;
    
    if (streaksQuery.empty) {
      // Create new streak
      streakRef = db.collection('users').doc(userId).collection('streaks').doc();
      currentData = {
        userId,
        type,
        currentStreak: 0,
        longestStreak: 0,
        lastActivityDate: null,
        streakDates: [],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      };
    } else {
      streakRef = streaksQuery.docs[0].ref;
      currentData = streaksQuery.docs[0].data();
    }
    
    // Check if activity already recorded for this date
    const lastActivity = currentData.lastActivityDate?.toDate();
    if (lastActivity && isSameDay(lastActivity, startOfDay)) {
      // Already recorded for this date
      res.json({
        streak: serializeTimestamps({
          id: streakRef.id,
          ...currentData,
          message: 'Activity already recorded for this date'
        })
      });
      return;
    }
    
    // Calculate if streak continues
    let newCurrentStreak = 1;
    if (lastActivity) {
      const daysDiff = Math.floor((startOfDay.getTime() - lastActivity.getTime()) / (1000 * 60 * 60 * 24));
      if (daysDiff === 1) {
        // Consecutive day
        newCurrentStreak = currentData.currentStreak + 1;
      } else if (daysDiff > 1) {
        // Streak broken
        newCurrentStreak = 1;
      }
    }
    
    // Update longest streak if necessary
    const newLongestStreak = Math.max(currentData.longestStreak, newCurrentStreak);
    
    // Update streak dates array
    let streakDates = currentData.streakDates || [];
    streakDates.push(startOfDay);
    
    // Keep only last 365 days
    if (streakDates.length > 365) {
      streakDates = streakDates.slice(-365);
    }
    
    // Update the streak
    const updates = {
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      lastActivityDate: startOfDay,
      streakDates,
      updatedAt: FieldValue.serverTimestamp()
    };
    
    if (streaksQuery.empty) {
      await streakRef.set({
        ...currentData,
        ...updates
      });
    } else {
      await streakRef.update(updates);
    }
    
    const updatedDoc = await streakRef.get();
    
    res.json({
      streak: serializeTimestamps({
        id: updatedDoc.id,
        ...updatedDoc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Get streak statistics
export const getStreakStatistics = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { period = 'month' } = req.query;
    
    const db = getFirestore();
    const snapshot = await db.collection('users').doc(userId).collection('streaks').get();
    
    const statistics: any = {
      byType: {
        reading: { current: 0, longest: 0, activeDays: 0 },
        chatMemo: { current: 0, longest: 0, activeDays: 0 },
        combined: { current: 0, longest: 0, activeDays: 0 }
      },
      totalActiveDays: 0,
      currentActiveTypes: 0
    };
    
    // Calculate period bounds
    const now = new Date();
    let startDate: Date;
    
    switch (period) {
      case 'week':
        startDate = new Date();
        startDate.setDate(startDate.getDate() - 7);
        break;
      case 'month':
        startDate = new Date();
        startDate.setMonth(startDate.getMonth() - 1);
        break;
      case 'year':
        startDate = new Date();
        startDate.setFullYear(startDate.getFullYear() - 1);
        break;
      default:
        throw new ApiError(400, 'INVALID_ARGUMENT', 'Invalid period');
    }
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      const type = data.type;
      
      if (statistics.byType[type]) {
        statistics.byType[type].current = data.currentStreak || 0;
        statistics.byType[type].longest = data.longestStreak || 0;
        
        // Count active days in period
        if (data.streakDates) {
          const activeDaysInPeriod = data.streakDates.filter((date: any) => {
            const d = date.toDate();
            return d >= startDate && d <= now;
          }).length;
          statistics.byType[type].activeDays = activeDaysInPeriod;
        }
        
        // Check if currently active
        if (data.lastActivityDate) {
          const lastActivity = data.lastActivityDate.toDate();
          const hoursSince = (now.getTime() - lastActivity.getTime()) / (1000 * 60 * 60);
          if (hoursSince < 48) {
            statistics.currentActiveTypes++;
          }
        }
      }
    });
    
    // Calculate total active days (unique days across all types)
    const allDates = new Set<string>();
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.streakDates) {
        data.streakDates.forEach((date: any) => {
          const d = date.toDate();
          if (d >= startDate && d <= now) {
            allDates.add(d.toISOString().split('T')[0]);
          }
        });
      }
    });
    statistics.totalActiveDays = allDates.size;
    
    res.json(serializeTimestamps({ statistics, period }));
  } catch (error) {
    next(error);
  }
};

// Reset a streak
export const resetStreak = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { streakId } = req.params;
    
    const db = getFirestore();
    const streakRef = db.collection('users').doc(userId).collection('streaks').doc(streakId);
    const doc = await streakRef.get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Streak not found');
    }
    
    await streakRef.update({
      currentStreak: 0,
      lastActivityDate: null,
      streakDates: [],
      updatedAt: FieldValue.serverTimestamp()
    });
    
    const updatedDoc = await streakRef.get();
    
    res.json({
      streak: serializeTimestamps({
        id: updatedDoc.id,
        ...updatedDoc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Helper function to check if two dates are the same day
function isSameDay(date1: Date, date2: Date): boolean {
  return date1.getFullYear() === date2.getFullYear() &&
         date1.getMonth() === date2.getMonth() &&
         date1.getDate() === date2.getDate();
}