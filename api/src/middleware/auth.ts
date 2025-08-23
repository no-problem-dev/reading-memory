import { Request, Response, NextFunction } from 'express';
import { getAuth } from '../config/firebase';
import { logger } from '../utils/logger';

export interface AuthRequest extends Request {
  user?: {
    uid: string;
    email?: string;
  };
}

export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        error: {
          code: 'UNAUTHENTICATED',
          message: '認証が必要です。',
        },
      });
      return;
    }
    
    const idToken = authHeader.split('Bearer ')[1];
    
    // Debug logging
    logger.info('Auth token info', {
      tokenLength: idToken.length,
      tokenPrefix: idToken.substring(0, 20) + '...',
      path: req.path,
      method: req.method
    });
    
    try {
      const decodedToken = await getAuth().verifyIdToken(idToken);
      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
      };
      next();
    } catch (error: any) {
      logger.error('Invalid ID token', {
        error: error.message,
        code: error.code,
        tokenLength: idToken.length
      });
      res.status(401).json({
        error: {
          code: 'INVALID_TOKEN',
          message: '無効な認証トークンです。',
        },
      });
    }
  } catch (error) {
    logger.error('Authentication error', error);
    res.status(500).json({
      error: {
        code: 'INTERNAL',
        message: '認証処理中にエラーが発生しました。',
      },
    });
  }
};

export const optionalAuth = async (
  req: AuthRequest,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    next();
    return;
  }
  
  const idToken = authHeader.split('Bearer ')[1];
  
  try {
    const decodedToken = await getAuth().verifyIdToken(idToken);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
    };
  } catch (error) {
    logger.warn('Optional auth failed, continuing without auth', error);
  }
  
  next();
};