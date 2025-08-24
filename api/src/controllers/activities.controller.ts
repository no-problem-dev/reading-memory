import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore } from '../config/firebase';
import { FieldValue, Query } from 'firebase-admin/firestore';
import { serializeTimestamps } from '../utils/timestamp';

// Get activities for a date range
export const getActivities = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { startDate, endDate, limit = 100 } = req.query;
    
    const db = getFirestore();
    let query: Query = db.collection('users').doc(userId).collection('activities');
    
    // Filter by date range if provided
    if (startDate) {
      query = query.where('date', '>=', new Date(String(startDate)));
    }
    
    if (endDate) {
      query = query.where('date', '<=', new Date(String(endDate)));
    }
    
    // Order by date descending
    query = query.orderBy('date', 'desc');
    
    // Limit results
    if (limit) {
      query = query.limit(Number(limit));
    }
    
    const snapshot = await query.get();
    const activities = snapshot.docs.map(doc => serializeTimestamps({
      id: doc.id,
      ...doc.data()
    }));
    
    res.json({ activities });
  } catch (error) {
    next(error);
  }
};

// Get activity for a specific date
export const getActivityByDate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { date } = req.params;
    
    // Create activity ID based on user and date
    const activityId = `${userId}_${date}`;
    
    const db = getFirestore();
    const doc = await db.collection('users').doc(userId).collection('activities').doc(activityId).get();
    
    if (!doc.exists) {
      // Return empty activity for the date
      res.json({
        id: activityId,
        userId,
        date: new Date(date),
        booksRead: 0,
        memosWritten: 0,
        pagesRead: null,
        readingMinutes: null
      });
    } else {
      res.json(serializeTimestamps({
        id: doc.id,
        ...doc.data()
      }));
    }
  } catch (error) {
    next(error);
  }
};

// Create or update activity
export const upsertActivity = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { date, booksRead, memosWritten, pagesRead, readingMinutes } = req.body;
    
    if (!date) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Date is required');
    }
    
    // Create activity ID based on user and date
    const activityDate = new Date(date);
    const dateString = activityDate.toISOString().split('T')[0];
    const activityId = `${userId}_${dateString}`;
    
    const db = getFirestore();
    const activityRef = db.collection('users').doc(userId).collection('activities').doc(activityId);
    
    const activityData = {
      userId,
      date: activityDate,
      booksRead: booksRead || 0,
      memosWritten: memosWritten || 0,
      pagesRead: pagesRead || null,
      readingMinutes: readingMinutes || null,
      updatedAt: FieldValue.serverTimestamp()
    };
    
    // Check if activity exists
    const doc = await activityRef.get();
    
    if (doc.exists) {
      // Update existing activity
      await activityRef.update(activityData);
    } else {
      // Create new activity
      await activityRef.set({
        ...activityData,
        id: activityId,
        createdAt: FieldValue.serverTimestamp()
      });
    }
    
    const updatedDoc = await activityRef.get();
    
    res.json(serializeTimestamps({
      id: updatedDoc.id,
      ...updatedDoc.data()
    }));
  } catch (error) {
    next(error);
  }
};

// Increment activity counters
export const incrementActivity = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { type, value = 1, date } = req.body;
    
    if (!type || !['booksRead', 'memosWritten', 'pagesRead', 'readingMinutes'].includes(type)) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Invalid activity type');
    }
    
    // Use today's date if not provided
    const activityDate = date ? new Date(date) : new Date();
    const dateString = activityDate.toISOString().split('T')[0];
    const activityId = `${userId}_${dateString}`;
    
    const db = getFirestore();
    const activityRef = db.collection('users').doc(userId).collection('activities').doc(activityId);
    
    // Get or create activity
    const doc = await activityRef.get();
    
    if (doc.exists) {
      // Increment existing activity
      await activityRef.update({
        [type]: FieldValue.increment(value),
        updatedAt: FieldValue.serverTimestamp()
      });
    } else {
      // Create new activity with initial value
      const newActivity = {
        id: activityId,
        userId,
        date: activityDate,
        booksRead: 0,
        memosWritten: 0,
        pagesRead: null,
        readingMinutes: null,
        [type]: value,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      };
      
      await activityRef.set(newActivity);
    }
    
    const updatedDoc = await activityRef.get();
    
    res.json(serializeTimestamps({
      id: updatedDoc.id,
      ...updatedDoc.data()
    }));
  } catch (error) {
    next(error);
  }
};

// Get activity summary
export const getActivitySummary = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { period = 'month' } = req.query;
    
    const db = getFirestore();
    let startDate: Date;
    const endDate = new Date();
    
    // Calculate start date based on period
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
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Invalid period. Use week, month, or year');
    }
    
    const query = db.collection('users')
      .doc(userId)
      .collection('activities')
      .where('date', '>=', startDate)
      .where('date', '<=', endDate);
    
    const snapshot = await query.get();
    
    // Calculate totals
    let totalBooksRead = 0;
    let totalMemosWritten = 0;
    let totalPagesRead = 0;
    let totalReadingMinutes = 0;
    let activeDays = 0;
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      totalBooksRead += data.booksRead || 0;
      totalMemosWritten += data.memosWritten || 0;
      totalPagesRead += data.pagesRead || 0;
      totalReadingMinutes += data.readingMinutes || 0;
      
      if (data.booksRead > 0 || data.memosWritten > 0) {
        activeDays++;
      }
    });
    
    res.json(serializeTimestamps({
      period,
      startDate,
      endDate,
      summary: {
        totalBooksRead,
        totalMemosWritten,
        totalPagesRead,
        totalReadingMinutes,
        activeDays,
        averageBooksPerDay: activeDays > 0 ? totalBooksRead / activeDays : 0,
        averageMemosPerDay: activeDays > 0 ? totalMemosWritten / activeDays : 0
      }
    }));
  } catch (error) {
    next(error);
  }
};