export interface Chat {
  id: string;
  message: string;
  messageType: 'user' | 'ai';
  imageId?: string;
  chapterOrSection?: string;
  pageNumber?: number;
  createdAt: Date | FirebaseFirestore.Timestamp;
  updatedAt: Date | FirebaseFirestore.Timestamp;
}

export interface CreateChatRequest {
  message: string;
  messageType?: 'user' | 'ai';
  imageId?: string;
  chapterOrSection?: string;
  pageNumber?: number;
}

export interface UpdateChatRequest {
  message: string;
  chapterOrSection?: string;
  pageNumber?: number;
}

export interface ChatResponse {
  chat: Chat;
}

export interface ChatsResponse {
  chats: Chat[];
}