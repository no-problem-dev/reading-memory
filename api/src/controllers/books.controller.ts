import { Response, NextFunction } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ApiError } from '../middleware/errorHandler';
import { BookSearchService } from '../services/bookSearchService';
import { config } from '../config';

export const searchBookByISBN = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const { isbn } = req.params;
    
    // Normalize ISBN (remove hyphens)
    const normalizedISBN = isbn.replace(/-/g, '');
    
    // Validate ISBN-10 or ISBN-13
    if (!/^(978|979)?\d{9}[\dX]$/.test(normalizedISBN)) {
      throw new ApiError(400, 'INVALID_ARGUMENT', 'ISBNの形式が正しくありません。');
    }
    
    const searchService = new BookSearchService(config.googleBooksApiKey);
    const results = await searchService.searchByISBN(normalizedISBN);
    
    if (results.length === 0) {
      throw new ApiError(404, 'NOT_FOUND', '該当する書籍が見つかりませんでした。');
    }
    
    res.json({
      books: results,
    });
  } catch (error) {
    next(error);
  }
};

export const searchBooksByQuery = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const query = req.query.q as string;
    
    const searchService = new BookSearchService(config.googleBooksApiKey);
    const results = await searchService.searchByQuery(query);
    
    res.json({
      books: results,
    });
  } catch (error) {
    next(error);
  }
};