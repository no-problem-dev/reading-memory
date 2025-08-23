import * as admin from 'firebase-admin';
import { config } from './index';
import { logger } from '../utils/logger';

export const initializeFirebase = async () => {
  try {
    if (config.isProduction) {
      // In production, use default application credentials
      admin.initializeApp({
        projectId: config.gcpProjectId,
        storageBucket: `${config.gcpProjectId}.appspot.com`,
      });
    } else {
      // In development, use service account key file or default credentials
      admin.initializeApp({
        projectId: config.gcpProjectId,
        storageBucket: `${config.gcpProjectId}.appspot.com`,
      });
    }
    
    logger.info('Firebase Admin SDK initialized');
  } catch (error) {
    logger.error('Failed to initialize Firebase', error);
    throw error;
  }
};

export const getFirestore = () => admin.firestore();
export const getAuth = () => admin.auth();
export const getStorage = () => admin.storage();