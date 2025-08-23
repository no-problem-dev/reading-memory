import { Router } from 'express';
import { optionalAuth } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { query } from 'express-validator';
import * as publicController from '../controllers/public.controller';

const router = Router();

// Get popular books
router.get(
  '/books/popular',
  optionalAuth,
  [
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  ],
  validateRequest,
  publicController.getPopularBooks
);

// Get recent books
router.get(
  '/books/recent',
  optionalAuth,
  [
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  ],
  validateRequest,
  publicController.getRecentBooks
);

// Search public books
router.get(
  '/books/search',
  optionalAuth,
  [
    query('q').notEmpty().withMessage('Search query is required'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  ],
  validateRequest,
  publicController.searchPublicBooks
);

export default router;