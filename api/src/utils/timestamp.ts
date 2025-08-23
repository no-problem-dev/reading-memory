import { Timestamp } from 'firebase-admin/firestore';

/**
 * Convert Firestore document data with Timestamps to JSON-serializable format
 */
export function serializeTimestamps(data: any): any {
  if (!data) return data;
  
  // Handle arrays
  if (Array.isArray(data)) {
    return data.map(item => serializeTimestamps(item));
  }
  
  // Handle objects
  if (typeof data === 'object') {
    const result: any = {};
    
    for (const [key, value] of Object.entries(data)) {
      if (value instanceof Timestamp) {
        // Convert Timestamp to ISO 8601 string
        result[key] = value.toDate().toISOString();
      } else if (value && typeof value === 'object') {
        // Recursively process nested objects
        result[key] = serializeTimestamps(value);
      } else {
        result[key] = value;
      }
    }
    
    return result;
  }
  
  return data;
}