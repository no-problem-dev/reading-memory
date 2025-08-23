import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { param, query } from 'express-validator';
import * as booksController from '../controllers/books.controller';

const router = Router();

// Search book by ISBN
router.get(
  '/search/isbn/:isbn',
  authenticate,
  [
    param('isbn').notEmpty().withMessage('ISBN is required'),
  ],
  validateRequest,
  booksController.searchBookByISBN
);

// Search books by query
router.get(
  '/search',
  authenticate,
  [
    query('q').notEmpty().withMessage('Search query is required'),
  ],
  validateRequest,
  booksController.searchBooksByQuery
);

export default router;