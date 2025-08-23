import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import { config } from './config';
import { errorHandler } from './middleware/errorHandler';
import { logger } from './utils/logger';
import authRoutes from './routes/auth.routes';
import aiRoutes from './routes/ai.routes';
import booksRoutes from './routes/books.routes';
import usersRoutes from './routes/users.routes';
import activitiesRoutes from './routes/activities.routes';
import goalsRoutes from './routes/goals.routes';
import achievementsRoutes from './routes/achievements.routes';
import streaksRoutes from './routes/streaks.routes';

export const createApp = (): Application => {
  const app = express();

  // Security middleware
  app.use(helmet());
  
  // CORS configuration
  app.use(cors(config.cors));
  
  // Compression middleware
  app.use(compression());
  
  // Body parsers
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));
  
  // Request logging
  app.use((req, _res, next) => {
    logger.info(`${req.method} ${req.path}`, {
      method: req.method,
      path: req.path,
      query: req.query,
      ip: req.ip,
    });
    next();
  });
  
  // Health check endpoint
  app.get('/health', (_req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
  });
  
  // API routes
  app.use('/api/v1/auth', authRoutes);
  app.use('/api/v1', usersRoutes);  // Changed to handle /api/v1/profile
  app.use('/api/v1/users', aiRoutes);
  app.use('/api/v1/books', booksRoutes);
  app.use('/api/v1/activities', activitiesRoutes);
  app.use('/api/v1/goals', goalsRoutes);
  app.use('/api/v1/achievements', achievementsRoutes);
  app.use('/api/v1/streaks', streaksRoutes);
  
  // 404 handler
  app.use((_req, res) => {
    res.status(404).json({
      error: {
        code: 'NOT_FOUND',
        message: 'Resource not found',
      },
    });
  });
  
  // Error handler
  app.use(errorHandler);
  
  return app;
};