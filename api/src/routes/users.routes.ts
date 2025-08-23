import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import * as usersController from '../controllers/users.controller';

const router = Router();

// Profile endpoints
router.get(
  '/profile',
  authenticate,
  usersController.getProfile
);

router.post(
  '/profile',
  authenticate,
  usersController.createProfile
);

router.put(
  '/profile',
  authenticate,
  usersController.updateProfile
);

// Delete account
router.delete(
  '/users/me',
  authenticate,
  usersController.deleteAccount
);

export default router;