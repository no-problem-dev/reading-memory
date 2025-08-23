import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
  getChats,
  createChat,
  updateChat,
  deleteChat
} from '../controllers/chats.controller';

const router = Router();

// All routes require authentication
router.use(authenticate);

// Chat routes (nested under books)
router.get('/books/:bookId/chats', getChats);
router.post('/books/:bookId/chats', createChat);
router.put('/books/:bookId/chats/:chatId', updateChat);
router.delete('/books/:bookId/chats/:chatId', deleteChat);

export default router;