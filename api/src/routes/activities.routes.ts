import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { param, query, body } from 'express-validator';
import * as activitiesController from '../controllers/activities.controller';

const router = Router();

// Get activities for a date range
router.get(
  '/',
  authenticate,
  [
    query('startDate').optional().isISO8601().withMessage('Invalid start date format'),
    query('endDate').optional().isISO8601().withMessage('Invalid end date format'),
    query('limit').optional().isInt({ min: 1, max: 365 }).withMessage('Limit must be between 1 and 365'),
  ],
  validateRequest,
  activitiesController.getActivities
);

// Get activity summary
router.get(
  '/summary',
  authenticate,
  [
    query('period').optional().isIn(['week', 'month', 'year']).withMessage('Invalid period'),
  ],
  validateRequest,
  activitiesController.getActivitySummary
);

// Get activity for a specific date
router.get(
  '/:date',
  authenticate,
  [
    param('date').matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('Date must be in YYYY-MM-DD format'),
  ],
  validateRequest,
  activitiesController.getActivityByDate
);

// Create or update activity
router.put(
  '/',
  authenticate,
  [
    body('date').isISO8601().withMessage('Invalid date format'),
    body('booksRead').optional().isInt({ min: 0 }).withMessage('Books read must be non-negative'),
    body('memosWritten').optional().isInt({ min: 0 }).withMessage('Memos written must be non-negative'),
    body('pagesRead').optional().isInt({ min: 0 }).withMessage('Pages read must be non-negative'),
    body('readingMinutes').optional().isInt({ min: 0 }).withMessage('Reading minutes must be non-negative'),
  ],
  validateRequest,
  activitiesController.upsertActivity
);

// Increment activity counter
router.post(
  '/increment',
  authenticate,
  [
    body('type').isIn(['booksRead', 'memosWritten', 'pagesRead', 'readingMinutes']).withMessage('Invalid activity type'),
    body('value').optional().isInt({ min: 1 }).withMessage('Value must be positive'),
    body('date').optional().isISO8601().withMessage('Invalid date format'),
  ],
  validateRequest,
  activitiesController.incrementActivity
);

export default router;