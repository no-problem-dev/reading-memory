import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { param, query, body } from 'express-validator';
import * as streaksController from '../controllers/streaks.controller';

const router = Router();

// Get all streaks
router.get(
  '/',
  authenticate,
  [
    query('type').optional().isIn(['reading', 'chatMemo', 'combined']).withMessage('Invalid streak type'),
  ],
  validateRequest,
  streaksController.getStreaks
);

// Get streak statistics
router.get(
  '/statistics',
  authenticate,
  [
    query('period').optional().isIn(['week', 'month', 'year']).withMessage('Invalid period'),
  ],
  validateRequest,
  streaksController.getStreakStatistics
);

// Get streak by type
router.get(
  '/type/:type',
  authenticate,
  [
    param('type').isIn(['reading', 'chatMemo', 'combined']).withMessage('Invalid streak type'),
  ],
  validateRequest,
  streaksController.getStreakByType
);

// Get a specific streak
router.get(
  '/:streakId',
  authenticate,
  [
    param('streakId').notEmpty().withMessage('Streak ID is required'),
  ],
  validateRequest,
  streaksController.getStreak
);

// Record activity
router.post(
  '/record',
  authenticate,
  [
    body('type').isIn(['reading', 'chatMemo', 'combined']).withMessage('Invalid streak type'),
    body('date').optional().isISO8601().withMessage('Invalid date format'),
  ],
  validateRequest,
  streaksController.recordActivity
);

// Reset a streak
router.post(
  '/:streakId/reset',
  authenticate,
  [
    param('streakId').notEmpty().withMessage('Streak ID is required'),
  ],
  validateRequest,
  streaksController.resetStreak
);

export default router;