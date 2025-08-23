import { createApp } from './app';
import { config } from './config';
import { logger } from './utils/logger';
import { initializeFirebase } from './config/firebase';

const startServer = async () => {
  try {
    // Initialize Firebase
    await initializeFirebase();
    
    // Create Express app
    const app = createApp();
    
    // Start server
    const server = app.listen(config.port, () => {
      logger.info(`Server is running on port ${config.port}`, {
        environment: config.env,
        port: config.port,
      });
    });
    
    // Graceful shutdown
    const shutdown = async () => {
      logger.info('Shutting down server...');
      server.close(() => {
        logger.info('Server closed');
        process.exit(0);
      });
    };
    
    process.on('SIGTERM', shutdown);
    process.on('SIGINT', shutdown);
    
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
};

startServer();