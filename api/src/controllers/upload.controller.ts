import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { getFirestore, getStorage } from '../config/firebase';
import { v4 as uuidv4 } from 'uuid';

// Helper function to upload file
const uploadFile = async (
  file: Express.Multer.File,
  filename: string
): Promise<string> => {
  const storage = getStorage();
  const bucket = storage.bucket();
  const blob = bucket.file(filename);
  
  return new Promise((resolve, reject) => {
    const stream = blob.createWriteStream({
      metadata: {
        contentType: file.mimetype,
      },
    });
    
    stream.on('error', (err) => {
      reject(new ApiError(500, 'INTERNAL_ERROR', 'Failed to upload image'));
    });
    
    stream.on('finish', async () => {
      try {
        // Make the file public
        await blob.makePublic();
        
        // Get the public URL
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filename}`;
        resolve(publicUrl);
      } catch (error) {
        reject(error);
      }
    });
    
    stream.end(file.buffer);
  });
};

// Upload profile image
export const uploadProfileImage = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const userId = req.user!.uid;
    const file = req.file;
    
    if (!file) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'No image file provided');
    }
    
    const filename = `users/${userId}/profile/${uuidv4()}.jpg`;
    const publicUrl = await uploadFile(file, filename);
    
    res.json({
      success: true,
      url: publicUrl,
    });
  } catch (error) {
    next(error);
  }
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
    
    if (!file) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'No image file provided');
    }
    
    // Check if book exists
    const db = getFirestore();
    const bookDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    if (!bookDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    const filename = `users/${userId}/books/${bookId}/cover.jpg`;
    const publicUrl = await uploadFile(file, filename);
    
    // Update book cover URL
    await bookDoc.ref.update({
      coverImageUrl: publicUrl,
    });
    
    res.json({
      success: true,
      url: publicUrl,
    });
  } catch (error) {
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
    const file = req.file;
    
    if (!file) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'No image file provided');
    }
    
    // Check if book exists
    const db = getFirestore();
    const bookDoc = await db.collection('users').doc(userId).collection('books').doc(bookId).get();
    if (!bookDoc.exists) {
      throw new ApiError(404, 'NOT_FOUND', 'Book not found');
    }
    
    const photoId = uuidv4();
    const filename = `books/${bookId}/photos/${photoId}.jpg`;
    const publicUrl = await uploadFile(file, filename);
    
    res.json({
      success: true,
      url: publicUrl,
      photoId: photoId,
    });
  } catch (error) {
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
    const { url } = req.body;
    
    if (!url) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'No image URL provided');
    }
    
    const storage = getStorage();
    const bucket = storage.bucket();
    
    // Extract filename from URL
    const bucketUrl = `https://storage.googleapis.com/${bucket.name}/`;
    if (!url.startsWith(bucketUrl)) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'Invalid image URL');
    }
    
    const filename = url.replace(bucketUrl, '');
    const file = bucket.file(filename);
    
    // Delete the file
    await file.delete();
    
    res.json({
      success: true,
    });
  } catch (error) {
    if ((error as any).code === 404) {
      // File not found is not an error
      res.json({
        success: true,
      });
    } else {
      next(error);
    }
  }
};