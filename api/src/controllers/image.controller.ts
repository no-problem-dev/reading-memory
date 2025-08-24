import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore, getStorage } from '../config/firebase';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';

interface ImageMetadata {
  id: string;
  uploadedBy: string;
  storagePath: string;
  url: string;
  contentType: string;
  size: number;
  metadata?: {
    width?: number;
    height?: number;
  };
  createdAt: Date;
  updatedAt: Date;
}

// Helper function to validate image file
const validateImageFile = (file: Express.Multer.File | undefined): Express.Multer.File => {
  if (!file) {
    throw new ApiError(400, 'INVALID_ARGUMENT', 'No image file provided');
  }

  // Max file size: 10MB
  const maxSize = 10 * 1024 * 1024;
  if (file.size > maxSize) {
    throw new ApiError(400, 'FILE_TOO_LARGE', 'File size exceeds 10MB limit');
  }

  // Allowed MIME types
  const allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png'];
  if (!allowedMimeTypes.includes(file.mimetype)) {
    throw new ApiError(400, 'INVALID_FILE_TYPE', 'Only JPEG and PNG images are allowed');
  }

  logger.info(`Image validation passed: ${file.originalname}, size: ${file.size}, mimetype: ${file.mimetype}`);
  return file;
};

// Upload image
export const uploadImage = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const file = req.file;
    
    logger.info(`Image upload request from user: ${userId}`);
    
    // Validate file
    const validatedFile = validateImageFile(file);
    
    // Generate image ID
    const imageId = uuidv4();
    const storagePath = `images/${imageId}.jpg`;
    
    // Upload to Firebase Storage
    const storage = getStorage();
    const bucket = storage.bucket();
    const blob = bucket.file(storagePath);
    
    logger.info(`Uploading image: ${storagePath}, size: ${validatedFile.size}`);
    
    await new Promise<void>((resolve, reject) => {
      const stream = blob.createWriteStream({
        metadata: {
          contentType: validatedFile.mimetype,
          cacheControl: 'public, max-age=31536000', // 1 year cache
          metadata: {
            uploadedBy: userId,
          }
        },
      });
      
      stream.on('error', (error) => {
        logger.error('Stream error during upload:', error);
        reject(new ApiError(500, 'UPLOAD_FAILED', 'Failed to upload image'));
      });
      
      stream.on('finish', () => {
        logger.info('Image uploaded successfully to Storage');
        resolve();
      });
      
      stream.end(validatedFile.buffer);
    });
    
    // Generate Firebase Storage URL
    const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(storagePath)}?alt=media`;
    
    // Save metadata to Firestore
    const db = getFirestore();
    const imageData: ImageMetadata = {
      id: imageId,
      uploadedBy: userId,
      storagePath,
      url,
      contentType: validatedFile.mimetype,
      size: validatedFile.size,
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    await db.collection('images').doc(imageId).set(imageData);
    logger.info(`Image metadata saved to Firestore: ${imageId}`);
    
    // Return response
    res.json({
      success: true,
      imageId,
      url
    });
  } catch (error) {
    logger.error('Image upload error:', error);
    next(error);
  }
};

// Get image info
export const getImage = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { imageId } = req.params;
    
    logger.info(`Get image request: imageId=${imageId}, userId=${userId}`);
    
    // Get image metadata from Firestore
    const db = getFirestore();
    const imageDoc = await db.collection('images').doc(imageId).get();
    
    if (!imageDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Image not found');
    }
    
    const imageData = imageDoc.data() as ImageMetadata;
    
    // Check if user has access to this image
    if (imageData.uploadedBy !== userId) {
      throw new ApiError(403, 'FORBIDDEN', 'You do not have access to this image');
    }
    
    res.json({
      id: imageData.id,
      url: imageData.url,
      contentType: imageData.contentType,
      size: imageData.size,
      metadata: imageData.metadata,
      createdAt: imageData.createdAt,
      updatedAt: imageData.updatedAt
    });
  } catch (error) {
    logger.error('Get image error:', error);
    next(error);
  }
};

// Delete image
export const deleteImage = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { imageId } = req.params;
    
    logger.info(`Delete image request: imageId=${imageId}, userId=${userId}`);
    
    // Get image metadata from Firestore
    const db = getFirestore();
    const imageDoc = await db.collection('images').doc(imageId).get();
    
    if (!imageDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Image not found');
    }
    
    const imageData = imageDoc.data() as ImageMetadata;
    
    // Check if user has permission to delete
    if (imageData.uploadedBy !== userId) {
      throw new ApiError(403, 'FORBIDDEN', 'You can only delete your own images');
    }
    
    // Delete from Storage
    const storage = getStorage();
    const bucket = storage.bucket();
    const file = bucket.file(imageData.storagePath);
    
    try {
      await file.delete();
      logger.info(`Image deleted from Storage: ${imageData.storagePath}`);
    } catch (error) {
      logger.warn(`Failed to delete image from Storage (may already be deleted): ${error}`);
    }
    
    // Delete metadata from Firestore
    await imageDoc.ref.delete();
    logger.info(`Image metadata deleted from Firestore: ${imageId}`);
    
    res.json({
      success: true
    });
  } catch (error) {
    logger.error('Delete image error:', error);
    next(error);
  }
};