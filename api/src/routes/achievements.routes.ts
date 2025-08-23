import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { param, query, body } from 'express-validator';
import * as achievementsController from '../controllers/achievements.controller';

const router = Router();

// Get all badges with user's achievements
router.get(
  '/badges',
  authenticate,
  [
    query('category').optional().isIn(['milestone', 'streak', 'genre', 'special']).withMessage('Invalid category'),
    query('isUnlocked').optional().isBoolean().withMessage('isUnlocked must be boolean'),
  ],
  validateRequest,
  achievementsController.getBadgesWithAchievements
);

// Get user's achievements only
router.get(
  '/',
  authenticate,
  [
    query('isUnlocked').optional().isBoolean().withMessage('isUnlocked must be boolean'),
  ],
  validateRequest,
  achievementsController.getAchievements
);

// Get achievement statistics
router.get(
  '/statistics',
  authenticate,
  achievementsController.getAchievementStatistics
);

// Check and update achievements
router.post(
  '/check',
  authenticate,
  achievementsController.checkAndUpdateAchievements
);

// Get a specific achievement
router.get(
  '/:achievementId',
  authenticate,
  [
    param('achievementId').notEmpty().withMessage('Achievement ID is required'),
  ],
  validateRequest,
  achievementsController.getAchievement
);

// Update achievement progress
router.patch(
  '/badge/:badgeId/progress',
  authenticate,
  [
    param('badgeId').notEmpty().withMessage('Badge ID is required'),
    body('progress').isFloat({ min: 0, max: 1 }).withMessage('Progress must be between 0 and 1'),
  ],
  validateRequest,
  achievementsController.updateAchievementProgress
);

export default router;