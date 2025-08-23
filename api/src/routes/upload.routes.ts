import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import * as uploadController from '../controllers/upload.controller';
import multer from 'multer';

const router = Router();

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (_req, file, cb) => {
    // Accept images only
    if (!file.originalname.match(/\.(jpg|jpeg|png|gif)$/)) {
      return cb(new Error('Only image files are allowed!'));
    }
    cb(null, true);
  },
});

// Upload profile image
router.post(
  '/profile-image',
  authenticate,
  upload.single('image'),
  uploadController.uploadProfileImage
);

// Upload book cover
router.post(
  '/books/:bookId/cover',
  authenticate,
  upload.single('image'),
  uploadController.uploadBookCover
);

// Upload chat photo
router.post(
  '/books/:bookId/chat-photo',
  authenticate,
  upload.single('image'),
  uploadController.uploadChatPhoto
);

// Delete image
router.delete(
  '/images',
  authenticate,
  uploadController.deleteImage
);

export default router;