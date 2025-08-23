import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';

export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export const errorHandler = (
  err: Error | ApiError,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  logger.error('Error caught by error handler', {
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });
  
  if (err instanceof ApiError) {
    res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
      },
    });
    return;
  }
  
  // Default error response
  res.status(500).json({
    error: {
      code: 'INTERNAL',
      message: 'サーバーエラーが発生しました。',
    },
  });
};