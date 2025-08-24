import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore } from '../config/firebase';
import { FieldValue, Query } from 'firebase-admin/firestore';
import { serializeTimestamps } from '../utils/timestamp';

// Badge definitions (would normally be in a separate config/database)
const BADGES: Record<string, any> = {
  // Milestone Badges
  first_book: {
    id: 'first_book',
    name: '読書デビュー',
    description: '初めての本を登録',
    iconName: 'book.fill',
    category: 'milestone',
    requirement: { type: 'booksRead', value: 1 },
    tier: 'bronze',
    sortOrder: 1
  },
  books_10: {
    id: 'books_10',
    name: '本の虫',
    description: '10冊の本を読了',
    iconName: 'books.vertical.fill',
    category: 'milestone',
    requirement: { type: 'booksRead', value: 10 },
    tier: 'bronze',
    sortOrder: 2
  },
  books_50: {
    id: 'books_50',
    name: '読書家',
    description: '50冊の本を読了',
    iconName: 'book.pages.fill',
    category: 'milestone',
    requirement: { type: 'booksRead', value: 50 },
    tier: 'silver',
    sortOrder: 3
  },
  books_100: {
    id: 'books_100',
    name: '読書マスター',
    description: '100冊の本を読了',
    iconName: 'crown.fill',
    category: 'milestone',
    requirement: { type: 'booksRead', value: 100 },
    tier: 'gold',
    sortOrder: 4
  },
  // Streak Badges
  streak_7: {
    id: 'streak_7',
    name: '読書習慣',
    description: '7日連続で読書',
    iconName: 'flame.fill',
    category: 'streak',
    requirement: { type: 'streakDays', value: 7 },
    tier: 'bronze',
    sortOrder: 10
  },
  streak_30: {
    id: 'streak_30',
    name: '読書の達人',
    description: '30日連続で読書',
    iconName: 'flame.circle.fill',
    category: 'streak',
    requirement: { type: 'streakDays', value: 30 },
    tier: 'silver',
    sortOrder: 11
  },
  streak_100: {
    id: 'streak_100',
    name: '読書の鬼',
    description: '100日連続で読書',
    iconName: 'star.circle.fill',
    category: 'streak',
    requirement: { type: 'streakDays', value: 100 },
    tier: 'gold',
    sortOrder: 12
  },
  // Special Badges
  yearly_goal: {
    id: 'yearly_goal',
    name: '目標達成',
    description: '年間読書目標を達成',
    iconName: 'target',
    category: 'special',
    requirement: { type: 'yearlyGoal', value: 1 },
    tier: 'gold',
    sortOrder: 20
  },
  memo_master: {
    id: 'memo_master',
    name: 'メモ魔',
    description: '100件のメモを記録',
    iconName: 'note.text',
    category: 'special',
    requirement: { type: 'memos', value: 100 },
    tier: 'silver',
    sortOrder: 21
  }
};

// Get all badges and user's achievements
export const getBadgesWithAchievements = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { category, isUnlocked } = req.query;
    
    const db = getFirestore();
    const achievementsSnapshot = await db.collection('users').doc(userId).collection('achievements').get();
    
    // Create achievement map
    const userAchievements = new Map();
    achievementsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      userAchievements.set(data.badgeId, {
        id: doc.id,
        ...data
      });
    });
    
    // Filter badges based on query params
    let badges = Object.values(BADGES);
    
    if (category) {
      badges = badges.filter(badge => badge.category === category);
    }
    
    // Combine badges with user achievements
    const result = badges.map(badge => {
      const achievement = userAchievements.get(badge.id);
      return {
        badge,
        achievement: serializeTimestamps(achievement || {
          id: null,
          badgeId: badge.id,
          userId,
          unlockedAt: null,
          progress: 0,
          isUnlocked: false
        })
      };
    });
    
    // Filter by unlock status if specified
    let filteredResult = result;
    if (isUnlocked !== undefined) {
      const unlocked = isUnlocked === 'true';
      filteredResult = result.filter(item => item.achievement.isUnlocked === unlocked);
    }
    
    // Sort by sortOrder
    filteredResult.sort((a, b) => a.badge.sortOrder - b.badge.sortOrder);
    
    res.json({ badgesWithAchievements: filteredResult });
  } catch (error) {
    next(error);
  }
};

// Get user's achievements only
export const getAchievements = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { isUnlocked } = req.query;
    
    const db = getFirestore();
    let query: Query = db.collection('users').doc(userId).collection('achievements');
    
    if (isUnlocked !== undefined) {
      query = query.where('isUnlocked', '==', isUnlocked === 'true');
    }
    
    const snapshot = await query.get();
    const achievements = snapshot.docs.map(doc => serializeTimestamps({
      id: doc.id,
      ...doc.data()
    }));
    
    res.json({ achievements });
  } catch (error) {
    next(error);
  }
};

// Get a specific achievement
export const getAchievement = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { achievementId } = req.params;
    
    const db = getFirestore();
    const doc = await db.collection('users').doc(userId).collection('achievements').doc(achievementId).get();
    
    if (!doc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Achievement not found');
    }
    
    res.json({
      achievement: serializeTimestamps({
        id: doc.id,
        ...doc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Update achievement progress
export const updateAchievementProgress = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { badgeId } = req.params;
    const { progress } = req.body;
    
    if (progress === undefined || progress < 0 || progress > 1) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Progress must be between 0 and 1');
    }
    
    // Check if badge exists
    if (!BADGES[badgeId as keyof typeof BADGES]) {
      throw new ApiError(404, 'NOT_FOUND', 'Badge not found');
    }
    
    const db = getFirestore();
    
    // Find or create achievement
    const achievementsQuery = await db.collection('users').doc(userId).collection('achievements')
      .where('badgeId', '==', badgeId)
      .limit(1)
      .get();
    
    let achievementRef;
    let isNew = false;
    
    if (achievementsQuery.empty) {
      // Create new achievement
      achievementRef = db.collection('users').doc(userId).collection('achievements').doc();
      isNew = true;
    } else {
      achievementRef = achievementsQuery.docs[0].ref;
    }
    
    const updates: any = {
      progress,
      updatedAt: FieldValue.serverTimestamp()
    };
    
    // Check if achievement should be unlocked
    if (progress >= 1) {
      updates.isUnlocked = true;
      updates.unlockedAt = FieldValue.serverTimestamp();
    }
    
    if (isNew) {
      await achievementRef.set({
        badgeId,
        userId,
        progress,
        isUnlocked: progress >= 1,
        unlockedAt: progress >= 1 ? FieldValue.serverTimestamp() : null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp()
      });
    } else {
      await achievementRef.update(updates);
    }
    
    const doc = await achievementRef.get();
    
    res.json({
      achievement: serializeTimestamps({
        id: doc.id,
        ...doc.data()
      })
    });
  } catch (error) {
    next(error);
  }
};

// Check and update achievements based on user stats
export const checkAndUpdateAchievements = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const db = getFirestore();
    
    // Get user statistics
    const booksCount = await db.collection('users').doc(userId).collection('books')
      .where('status', '==', 'completed')
      .get()
      .then(snapshot => snapshot.size);
    
    const memosCount = await db.collection('users').doc(userId).collection('books')
      .get()
      .then(async booksSnapshot => {
        let totalMemos = 0;
        for (const bookDoc of booksSnapshot.docs) {
          const chatsSnapshot = await bookDoc.ref.collection('chats').get();
          totalMemos += chatsSnapshot.size;
        }
        return totalMemos;
      });
    
    // Get current streak (simplified - would need proper implementation)
    // const streakDays = 0; // TODO: Calculate actual streak
    
    // Check each badge requirement
    const updates: any[] = [];
    
    // Check book count achievements
    if (booksCount >= 1) {
      updates.push({ badgeId: 'first_book', progress: 1 });
    }
    if (booksCount >= 10) {
      updates.push({ badgeId: 'books_10', progress: 1 });
    } else if (booksCount > 0) {
      updates.push({ badgeId: 'books_10', progress: booksCount / 10 });
    }
    if (booksCount >= 50) {
      updates.push({ badgeId: 'books_50', progress: 1 });
    } else if (booksCount > 10) {
      updates.push({ badgeId: 'books_50', progress: booksCount / 50 });
    }
    if (booksCount >= 100) {
      updates.push({ badgeId: 'books_100', progress: 1 });
    } else if (booksCount > 50) {
      updates.push({ badgeId: 'books_100', progress: booksCount / 100 });
    }
    
    // Check memo achievements
    if (memosCount >= 100) {
      updates.push({ badgeId: 'memo_master', progress: 1 });
    } else if (memosCount > 0) {
      updates.push({ badgeId: 'memo_master', progress: memosCount / 100 });
    }
    
    // Update all achievements
    const updatedAchievements = [];
    for (const update of updates) {
      const result = await updateSingleAchievement(db, userId, update.badgeId, update.progress);
      updatedAchievements.push(result);
    }
    
    res.json(serializeTimestamps({
      checkedBadges: updates.length,
      updatedAchievements
    }));
  } catch (error) {
    next(error);
  }
};

// Helper function to update a single achievement
async function updateSingleAchievement(db: any, userId: string, badgeId: string, progress: number) {
  const achievementsQuery = await db.collection('users').doc(userId).collection('achievements')
    .where('badgeId', '==', badgeId)
    .limit(1)
    .get();
  
  let achievementRef;
  let isNew = false;
  
  if (achievementsQuery.empty) {
    achievementRef = db.collection('users').doc(userId).collection('achievements').doc();
    isNew = true;
  } else {
    achievementRef = achievementsQuery.docs[0].ref;
  }
  
  const updates: any = {
    progress,
    updatedAt: FieldValue.serverTimestamp()
  };
  
  if (progress >= 1) {
    updates.isUnlocked = true;
    updates.unlockedAt = FieldValue.serverTimestamp();
  }
  
  if (isNew) {
    await achievementRef.set({
      badgeId,
      userId,
      progress,
      isUnlocked: progress >= 1,
      unlockedAt: progress >= 1 ? FieldValue.serverTimestamp() : null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp()
    });
  } else {
    await achievementRef.update(updates);
  }
  
  const doc = await achievementRef.get();
  return serializeTimestamps({
    id: doc.id,
    ...doc.data()
  });
}

// Get achievement statistics
export const getAchievementStatistics = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    
    const db = getFirestore();
    const snapshot = await db.collection('users').doc(userId).collection('achievements').get();
    
    const totalBadges = Object.keys(BADGES).length;
    let unlockedCount = 0;
    let bronzeCount = 0;
    let silverCount = 0;
    let goldCount = 0;
    
    const unlockedBadgeIds = new Set();
    
    snapshot.docs.forEach(doc => {
      const data = doc.data();
      if (data.isUnlocked) {
        unlockedCount++;
        unlockedBadgeIds.add(data.badgeId);
      }
    });
    
    // Count by tier
    unlockedBadgeIds.forEach((badgeId: any) => {
      const badge = BADGES[badgeId as keyof typeof BADGES];
      if (badge) {
        switch (badge.tier) {
        case 'bronze':
          bronzeCount++;
          break;
        case 'silver':
          silverCount++;
          break;
        case 'gold':
          goldCount++;
          break;
        }
      }
    });
    
    res.json({
      statistics: {
        totalBadges,
        unlockedCount,
        lockedCount: totalBadges - unlockedCount,
        completionRate: totalBadges > 0 ? unlockedCount / totalBadges : 0,
        byTier: {
          bronze: bronzeCount,
          silver: silverCount,
          gold: goldCount
        }
      }
    });
  } catch (error) {
    next(error);
  }
};