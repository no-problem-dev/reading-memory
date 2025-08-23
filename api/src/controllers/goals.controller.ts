import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore } from '../config/firebase';
import { FieldValue, Query } from 'firebase-admin/firestore';
import { serializeTimestamps } from '../utils/timestamp';

// Get all goals
export const getGoals = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { isActive, type, period } = req.query;
    
    const db = getFirestore();
    let query: Query = db.collection('users').doc(userId).collection('goals');
    
    // Filter by active status
    if (isActive !== undefined) {
      query = query.where('isActive', '==', isActive === 'true');
    }
    
    // Filter by type
    if (type) {
      query = query.where('type', '==', type);
    }
    
    // Filter by period
    if (period) {
      query = query.where('period', '==', period);
    }
    
    // Order by created date descending
    query = query.orderBy('createdAt', 'desc');
    
    const snapshot = await query.get();
    const goals = snapshot.docs.map(doc => serializeTimestamps({
      id: doc.id,
      ...doc.data()
    }));
    
    res.json({ goals });
  } catch (error) {
    next(error);
  }
};

// Get a specific goal
export const getGoal = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { goalId } = req.params;
    
    const db = getFirestore();
    const doc = await db.collection('users').doc(userId).collection('goals').doc(goalId).get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Goal not found');
    }
    
    res.json({
      goal: serializeTimestamps({
        id: doc.id,
        ...doc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Create a new goal
export const createGoal = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { type, targetValue, period, startDate, endDate } = req.body;
    
    // Validate required fields
    if (!type || !targetValue || !period || !startDate || !endDate) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Missing required fields');
    }
    
    // Validate dates
    const start = new Date(startDate);
    const end = new Date(endDate);
    
    if (start >= end) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'End date must be after start date');
    }
    
    const goalData = {
      userId,
      type,
      targetValue,
      currentValue: 0,
      period,
      startDate: start,
      endDate: end,
      isActive: true,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    };
    
    const db = getFirestore();
    const docRef = await db.collection('users').doc(userId).collection('goals').add(goalData);
    const doc = await docRef.get();
    
    res.status(201).json({
      goal: serializeTimestamps({
        id: doc.id,
        ...doc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Update a goal
export const updateGoal = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { goalId } = req.params;
    const updates = req.body;
    
    // Remove fields that shouldn't be updated
    delete updates.id;
    delete updates.userId;
    delete updates.createdAt;
    
    // Validate dates if provided
    if (updates.startDate && updates.endDate) {
      const start = new Date(updates.startDate);
      const end = new Date(updates.endDate);
      
      if (start >= end) {
        throw new ApiError(400, 'INVALID_ARGUMENT', 'End date must be after start date');
      }
    }
    
    // Add updated timestamp
    updates.updatedAt = FieldValue.serverTimestamp();
    
    const db = getFirestore();
    const goalRef = db.collection('users').doc(userId).collection('goals').doc(goalId);
    const doc = await goalRef.get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Goal not found');
    }
    
    await goalRef.update(updates);
    const updatedDoc = await goalRef.get();
    
    res.json({
      goal: serializeTimestamps({
        id: updatedDoc.id,
        ...updatedDoc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Delete a goal
export const deleteGoal = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { goalId } = req.params;
    
    const db = getFirestore();
    const goalRef = db.collection('users').doc(userId).collection('goals').doc(goalId);
    const doc = await goalRef.get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Goal not found');
    }
    
    await goalRef.delete();
    
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

// Update goal progress
export const updateGoalProgress = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { goalId } = req.params;
    const { increment, setValue } = req.body;
    
    if (increment === undefined && setValue === undefined) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Either increment or setValue must be provided');
    }
    
    const db = getFirestore();
    const goalRef = db.collection('users').doc(userId).collection('goals').doc(goalId);
    const doc = await goalRef.get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Goal not found');
    }
    
    const updates: any = {
      updatedAt: FieldValue.serverTimestamp()
    };
    
    if (increment !== undefined) {
      updates.currentValue = FieldValue.increment(increment);
    } else if (setValue !== undefined) {
      updates.currentValue = setValue;
    }
    
    await goalRef.update(updates);
    const updatedDoc = await goalRef.get();
    
    res.json({
      goal: serializeTimestamps({
        id: updatedDoc.id,
        ...updatedDoc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Get goal statistics
export const getGoalStatistics = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    
    const db = getFirestore();
    const snapshot = await db.collection('users').doc(userId).collection('goals').get();
    
    let totalGoals = 0;
    let activeGoals = 0;
    let completedGoals = 0;
    let totalProgress = 0;
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      totalGoals++;
      
      if (data.isActive) {
        activeGoals++;
      }
      
      if (data.currentValue >= data.targetValue) {
        completedGoals++;
      }
      
      const progress = Math.min(data.currentValue / data.targetValue, 1);
      totalProgress += progress;
    });
    
    const averageProgress = totalGoals > 0 ? totalProgress / totalGoals : 0;
    
    res.json({
      statistics: {
        totalGoals,
        activeGoals,
        completedGoals,
        averageProgress,
        completionRate: totalGoals > 0 ? completedGoals / totalGoals : 0
      }
    });
  } catch (error) {
    next(error);
  }
};