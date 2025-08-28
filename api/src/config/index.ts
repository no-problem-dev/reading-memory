import dotenv from 'dotenv';
dotenv.config();

export const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '8080', 10),
  isProduction: process.env.NODE_ENV === 'production',
  googleBooksApiKey: process.env.GOOGLE_BOOKS_API_KEY || '',
  claudeApiKey: process.env.CLAUDE_API_KEY || '',
  rakutenApplicationId: process.env.RAKUTEN_APPLICATION_ID || '',
  rakutenAffiliateId: process.env.RAKUTEN_AFFILIATE_ID || '',
  gcpProjectId: process.env.GCP_PROJECT_ID || 'reading-memory',
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || process.env.GCP_PROJECT_ID || 'reading-memory',
  },
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  },
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },
};