import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import * as usersController from '../controllers/users.controller';

const router = Router();

// Delete account
router.delete(
  '/me',
  authenticate,
  usersController.deleteAccount
);

export default router;