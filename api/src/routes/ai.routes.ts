import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { validateRequest } from '../middleware/validation';
import { body, param } from 'express-validator';
import * as aiController from '../controllers/ai.controller';

const router = Router();

// Generate AI response for book chat
router.post(
  '/:userId/books/:userBookId/ai-response',
  authenticate,
  [
    param('userId').notEmpty().withMessage('User ID is required'),
    param('userBookId').notEmpty().withMessage('User Book ID is required'),
    body('message').notEmpty().withMessage('Message is required'),
  ],
  validateRequest,
  aiController.generateAIResponse
);

// Generate book summary
router.post(
  '/:userId/books/:userBookId/summary',
  authenticate,
  [
    param('userId').notEmpty().withMessage('User ID is required'),
    param('userBookId').notEmpty().withMessage('User Book ID is required'),
  ],
  validateRequest,
  aiController.generateBookSummary
);

export default router;