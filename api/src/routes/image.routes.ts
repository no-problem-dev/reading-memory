import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { uploadImage, getImage, deleteImage } from '../controllers/image.controller';
import multer from 'multer';

const router = Router();

// Configure multer for memory storage
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
});

// All routes require authentication
router.use(authenticate);

// Upload a new image
router.post('/', upload.single('image'), uploadImage);

// Get image information
router.get('/:imageId', getImage);

// Delete an image
router.delete('/:imageId', deleteImage);

export default router;