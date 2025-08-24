import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore, getStorage } from '../config/firebase';
import { v4 as uuidv4 } from 'uuid';
import { logger } from '../utils/logger';

interface UploadConfig {
  pathTemplate: string;
  fileType: 'single' | 'multiple';
  maxSize: number;
  allowedMimeTypes: string[];
  shouldDeleteOld: boolean;
}

// Upload configurations
const UPLOAD_CONFIGS: Record<string, UploadConfig> = {
  profileImage: {
    pathTemplate: 'users/{userId}/profile/avatar.jpg',
    fileType: 'single',
    maxSize: 5 * 1024 * 1024, // 5MB
    allowedMimeTypes: ['image/jpeg', 'image/jpg', 'image/png'],
    shouldDeleteOld: true
  },
  bookCover: {
    pathTemplate: 'users/{userId}/books/{bookId}/cover.jpg',
    fileType: 'single',
    maxSize: 5 * 1024 * 1024, // 5MB
    allowedMimeTypes: ['image/jpeg', 'image/jpg', 'image/png'],
    shouldDeleteOld: true
  },
  chatPhoto: {
    pathTemplate: 'users/{userId}/books/{bookId}/chat-photos/{photoId}.jpg',
    fileType: 'multiple',
    maxSize: 10 * 1024 * 1024, // 10MB
    allowedMimeTypes: ['image/jpeg', 'image/jpg', 'image/png'],
    shouldDeleteOld: false
  }
};

// Helper function to validate file
const validateFile = (file: Express.Multer.File | undefined, config: UploadConfig): Express.Multer.File => {
  if (!file) {
    throw new ApiError(400, 'INVALID_ARGUMENT', 'No image file provided');
  }

  if (file.size > config.maxSize) {
    throw new ApiError(400, 'FILE_TOO_LARGE', `File size exceeds ${config.maxSize / (1024 * 1024)}MB limit`);
  }

  if (!config.allowedMimeTypes.includes(file.mimetype)) {
    throw new ApiError(400, 'INVALID_FILE_TYPE', 'Only JPEG and PNG images are allowed');
  }

  logger.info(`File validation passed: ${file.originalname}, size: ${file.size}, mimetype: ${file.mimetype}`);
  return file;
};

// Helper function to delete old file
const deleteOldFile = async (filename: string): Promise<void> => {
  try {
    const storage = getStorage();
    const bucket = storage.bucket();
    const file = bucket.file(filename);
    
    const [exists] = await file.exists();
    if (exists) {
      await file.delete();
      logger.info(`Old file deleted: ${filename}`);
    }
  } catch (error) {
    logger.warn(`Failed to delete old file ${filename}:`, error);
    // Don't throw error, just log warning
  }
};

// Helper function to upload file
const uploadFile = async (
  file: Express.Multer.File,
  filename: string,
  shouldDeleteOld: boolean = false
): Promise<string> => {
  const storage = getStorage();
  const bucket = storage.bucket();
  
  logger.info(`Uploading file: ${filename}, mimetype: ${file.mimetype}, size: ${file.size}, bucket: ${bucket.name}`);
  
  // Delete old file if requested
  if (shouldDeleteOld) {
    await deleteOldFile(filename);
  }
  
  const blob = bucket.file(filename);
  
  return new Promise((resolve, reject) => {
    const stream = blob.createWriteStream({
      metadata: {
        contentType: file.mimetype,
        cacheControl: 'public, max-age=86400', // 24 hours cache
      },
    });
    
    stream.on('error', (error) => {
      logger.error('Stream error during upload:', error);
      reject(new ApiError(500, 'UPLOAD_FAILED', 'Failed to upload image to storage'));
    });
    
    stream.on('finish', async () => {
      try {
        // Make the file public
        await blob.makePublic();
        
        // Get the public URL
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filename}`;
        logger.info(`Upload successful: ${publicUrl}`);
        resolve(publicUrl);
      } catch (error) {
        logger.error('Error making file public:', error);
        reject(new ApiError(500, 'UPLOAD_FAILED', 'Failed to make uploaded file public'));
      }
    });
    
    stream.end(file.buffer);
  });
};

// Helper function to build file path
const buildFilePath = (template: string, params: Record<string, string>): string => {
  let path = template;
  Object.entries(params).forEach(([key, value]) => {
    path = path.replace(`{${key}}`, value);
  });
  return path;
};

// Generic upload function
const handleUpload = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction,
  configKey: string,
  pathParams: Record<string, string>
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const file = req.file;
    const config = UPLOAD_CONFIGS[configKey];
    
    logger.info(`${configKey} upload request for user: ${userId}`, pathParams);
    
    // Validate file
    const validatedFile = validateFile(file, config);
    
    // Build file path
    const allParams = { userId, ...pathParams };
    const filename = buildFilePath(config.pathTemplate, allParams);
    
    // Upload file
    const publicUrl = await uploadFile(validatedFile, filename, config.shouldDeleteOld);
    
    // Build response
    const response: any = {
      success: true,
      url: publicUrl,
    };
    
    // Add photoId for multiple file uploads
    if (config.fileType === 'multiple' && pathParams.photoId) {
      response.photoId = pathParams.photoId;
    }
    
    res.json(response);
  } catch (error) {
    logger.error(`${configKey} upload error:`, error);
    next(error);
  }
};

// Upload profile image
export const uploadProfileImage = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  await handleUpload(req, res, next, 'profileImage', {});
};

// Upload book cover
export const uploadBookCover = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { bookId } = req.params;
    const file = req.file;
    const config = UPLOAD_CONFIGS['bookCover'];
    
    logger.info(`Book cover upload request for user: ${userId}, book: ${bookId}`);
    
    // Check if book exists
    const db = getFirestore();
    const bookDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    if (!bookDoc.exists) {
      logger.error(`Book not found: userId=${userId}, bookId=${bookId}`);
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    // Validate file
    const validatedFile = validateFile(file, config);
    
    // Build file path
    const filename = buildFilePath(config.pathTemplate, { userId, bookId });
    
    // Upload file
    const publicUrl = await uploadFile(validatedFile, filename, config.shouldDeleteOld);
    
    // Update book cover URL in Firestore
    await bookDoc.ref.update({
      coverImageUrl: publicUrl,
      updatedAt: new Date()
    });
    logger.info(`Book cover URL updated in Firestore: ${bookId}`);
    
    res.json({
      success: true,
      url: publicUrl,
    });
  } catch (error) {
    logger.error('Book cover upload error:', error);
    next(error);
  }
};

// Upload chat photo
export const uploadChatPhoto = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const { bookId } = req.params;
    
    logger.info(`Chat photo upload request for user: ${userId}, book: ${bookId}`);
    
    // Check if book exists
    const db = getFirestore();
    const bookDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    if (!bookDoc.exists) {
      logger.error(`Book not found for chat photo upload: userId=${userId}, bookId=${bookId}`);
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    const photoId = uuidv4();
    await handleUpload(req, res, next, 'chatPhoto', { bookId, photoId });
  } catch (error) {
    logger.error('Chat photo upload error:', error);
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
    const { url } = req.body;
    
    if (!url) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'No image URL provided');
    }
    
    logger.info(`Delete image request for user: ${userId}, url: ${url}`);
    
    const storage = getStorage();
    const bucket = storage.bucket();
    
    // Extract filename from URL
    const bucketUrl = `https://storage.googleapis.com/${bucket.name}/`;
    if (!url.startsWith(bucketUrl)) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Invalid image URL');
    }
    
    const filename = url.replace(bucketUrl, '');
    
    // Validate that the file belongs to the requesting user
    if (!filename.startsWith(`users/${userId}/`)) {
      logger.error(`Unauthorized delete attempt: userId=${userId}, filename=${filename}`);
      throw new ApiError(403, 'FORBIDDEN', 'You can only delete your own images');
    }
    
    const file = bucket.file(filename);
    
    // Delete the file
    await file.delete();
    logger.info(`Image deleted successfully: ${filename}`);
    
    res.json({
      success: true,
    });
  } catch (error) {
    if ((error as any).code === 404) {
      // File not found is not an error for delete operations
      logger.info('File not found during delete, considering as success');
      res.json({
        success: true,
      });
    } else {
      logger.error('Delete image error:', error);
      next(error);
    }
  }
};