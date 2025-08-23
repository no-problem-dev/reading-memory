import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { param, query, body } from 'express-validator';
import * as booksController from '../controllers/books.controller';
import * as chatsController from '../controllers/chats.controller';

const router = Router();

// Search endpoints
router.get(
  '/search/isbn/:isbn',
  authenticate,
  [
    param('isbn').notEmpty().withMessage('ISBN is required'),
  ],
  validateRequest,
  booksController.searchBookByISBN
);

router.get(
  '/search',
  authenticate,
  [
    query('q').notEmpty().withMessage('Search query is required'),
  ],
  validateRequest,
  booksController.searchBooksByQuery
);

// CRUD endpoints
router.get(
  '/',
  authenticate,
  [
    query('status').optional().isIn(['want_to_read', 'reading', 'completed', 'dnf']).withMessage('Invalid status'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('startAfter').optional(),
  ],
  validateRequest,
  booksController.getBooks
);

router.get(
  '/want-to-read',
  authenticate,
  booksController.getWantToReadBooks
);

router.get(
  '/reading',
  authenticate,
  booksController.getReadingBooks
);

router.get(
  '/completed',
  authenticate,
  booksController.getCompletedBooks
);

router.get(
  '/:bookId',
  authenticate,
  [
    param('bookId').notEmpty().withMessage('Book ID is required'),
  ],
  validateRequest,
  booksController.getBook
);

router.post(
  '/',
  authenticate,
  [
    body('title').notEmpty().withMessage('Title is required'),
    body('author').notEmpty().withMessage('Author is required'),
    body('status').isIn(['want_to_read', 'reading', 'completed', 'dnf']).withMessage('Invalid status'),
    body('dataSource').isIn(['manual', 'google_books', 'openbd', 'rakuten_books']).withMessage('Invalid data source'),
  ],
  validateRequest,
  booksController.createBook
);

router.put(
  '/:bookId',
  authenticate,
  [
    param('bookId').notEmpty().withMessage('Book ID is required'),
  ],
  validateRequest,
  booksController.updateBook
);

router.delete(
  '/:bookId',
  authenticate,
  [
    param('bookId').notEmpty().withMessage('Book ID is required'),
  ],
  validateRequest,
  booksController.deleteBook
);

// Chat endpoints
router.get(
  '/:bookId/chats',
  authenticate,
  [
    param('bookId').notEmpty().withMessage('Book ID is required'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('startAfter').optional(),
  ],
  validateRequest,
  chatsController.getChats
);

router.post(
  '/:bookId/chats',
  authenticate,
  [
    param('bookId').notEmpty().withMessage('Book ID is required'),
    body('message').notEmpty().withMessage('Message is required'),
    body('messageType').optional().isIn(['user', 'ai']).withMessage('Invalid message type'),
  ],
  validateRequest,
  chatsController.createChat
);

router.put(
  '/:bookId/chats/:chatId',
  authenticate,
  [
    param('bookId').notEmpty().withMessage('Book ID is required'),
    param('chatId').notEmpty().withMessage('Chat ID is required'),
    body('message').notEmpty().withMessage('Message is required'),
  ],
  validateRequest,
  chatsController.updateChat
);

router.delete(
  '/:bookId/chats/:chatId',
  authenticate,
  [
    param('bookId').notEmpty().withMessage('Book ID is required'),
    param('chatId').notEmpty().withMessage('Chat ID is required'),
  ],
  validateRequest,
  chatsController.deleteChat
);

export default router;