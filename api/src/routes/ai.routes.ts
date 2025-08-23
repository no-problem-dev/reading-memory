import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { body, param } from 'express-validator';
import * as aiController from '../controllers/ai.controller';

const router = Router();

// Generate AI response for book chat
router.post(
  '/books/:bookId/ai-response',
  authenticate,
  [
    param('bookId').notEmpty().withMessage('Book ID is required'),
    body('message').notEmpty().withMessage('Message is required'),
  ],
  validateRequest,
  aiController.generateAIResponse
);

// Generate book summary
router.post(
  '/books/:bookId/summary',
  authenticate,
  [
    param('bookId').notEmpty().withMessage('Book ID is required'),
  ],
  validateRequest,
  aiController.generateBookSummary
);

export default router;