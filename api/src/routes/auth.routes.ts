import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import * as authController from '../controllers/auth.controller';

const router = Router();

// Initialize user data after authentication
router.post(
  '/initialize',
  authenticate,
  authController.initializeUser
);

// Check if user needs onboarding
router.get(
  '/onboarding-status',
  authenticate,
  authController.getOnboardingStatus
);

// Complete onboarding
router.post(
  '/complete-onboarding',
  authenticate,
  authController.completeOnboarding
);

export default router;