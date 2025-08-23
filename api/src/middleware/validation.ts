import { Request, Response, NextFunction } from 'express';
import { validationResult } from 'express-validator';

export const validateRequest = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    res.status(400).json({
      error: {
        code: 'INVALID_ARGUMENT',
        message: 'リクエストパラメータが不正です。',
        details: errors.array(),
      },
    });
    return;
  }
  
  next();
};