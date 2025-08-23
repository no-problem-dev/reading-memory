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
      } else if (value instanceof Date) {
        // Convert Date to ISO 8601 string
        result[key] = value.toISOString();
      } else if (
        typeof value === 'number' && 
        (key.toLowerCase().includes('date') || key.toLowerCase().includes('at')) &&
        value > 0 && value < 2000000000 // Unix timestamp range check (before year 2033)
      ) {
        // Convert Unix timestamp (seconds) to ISO 8601 string
        result[key] = new Date(value * 1000).toISOString();
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