import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { param, query, body } from 'express-validator';
import * as goalsController from '../controllers/goals.controller';

const router = Router();

// Get all goals
router.get(
  '/',
  authenticate,
  [
    query('isActive').optional().isBoolean().withMessage('isActive must be boolean'),
    query('type').optional().isIn(['bookCount', 'readingDays', 'genreCount', 'custom']).withMessage('Invalid goal type'),
    query('period').optional().isIn(['yearly', 'monthly', 'quarterly', 'custom']).withMessage('Invalid goal period'),
  ],
  validateRequest,
  goalsController.getGoals
);

// Get goal statistics
router.get(
  '/statistics',
  authenticate,
  goalsController.getGoalStatistics
);

// Get a specific goal
router.get(
  '/:goalId',
  authenticate,
  [
    param('goalId').notEmpty().withMessage('Goal ID is required'),
  ],
  validateRequest,
  goalsController.getGoal
);

// Create a new goal
router.post(
  '/',
  authenticate,
  [
    body('type').isIn(['bookCount', 'readingDays', 'genreCount', 'custom']).withMessage('Invalid goal type'),
    body('targetValue').isInt({ min: 1 }).withMessage('Target value must be positive'),
    body('period').isIn(['yearly', 'monthly', 'quarterly', 'custom']).withMessage('Invalid goal period'),
    body('startDate').isISO8601().withMessage('Invalid start date format'),
    body('endDate').isISO8601().withMessage('Invalid end date format'),
  ],
  validateRequest,
  goalsController.createGoal
);

// Update a goal
router.put(
  '/:goalId',
  authenticate,
  [
    param('goalId').notEmpty().withMessage('Goal ID is required'),
    body('type').optional().isIn(['bookCount', 'readingDays', 'genreCount', 'custom']).withMessage('Invalid goal type'),
    body('targetValue').optional().isInt({ min: 1 }).withMessage('Target value must be positive'),
    body('period').optional().isIn(['yearly', 'monthly', 'quarterly', 'custom']).withMessage('Invalid goal period'),
    body('startDate').optional().isISO8601().withMessage('Invalid start date format'),
    body('endDate').optional().isISO8601().withMessage('Invalid end date format'),
    body('isActive').optional().isBoolean().withMessage('isActive must be boolean'),
  ],
  validateRequest,
  goalsController.updateGoal
);

// Update goal progress
router.patch(
  '/:goalId/progress',
  authenticate,
  [
    param('goalId').notEmpty().withMessage('Goal ID is required'),
    body('increment').optional().isInt().withMessage('Increment must be an integer'),
    body('setValue').optional().isInt({ min: 0 }).withMessage('Value must be non-negative'),
  ],
  validateRequest,
  goalsController.updateGoalProgress
);

// Delete a goal
router.delete(
  '/:goalId',
  authenticate,
  [
    param('goalId').notEmpty().withMessage('Goal ID is required'),
  ],
  validateRequest,
  goalsController.deleteGoal
);

export default router;