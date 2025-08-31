import Foundation
import UIKit

@MainActor
@Observable
final class BookChatViewModel: BaseViewModel {
    var chats: [BookChat] = []
    
    let book: Book
    private let repository = BookChatRepository.shared
    private let authService = AuthService.shared
    private let aiService = AIService.shared
    private let activityRepository = ActivityRepository.shared
    
    var isAIEnabled = false // AI機能の有効/無効フラグ
    var showPaywall = false
    
    init(book: Book) {
        self.book = book
    }
    
    func loadChats() async {
        do {
            isLoading = true
            let loadedChats = try await repository.getChats(
                bookId: book.id
            )
            chats = loadedChats
            print("Loaded \(loadedChats.count) chats for book: \(book.title)")
        } catch {
            // キャンセルエラーは無視（プルダウンリフレッシュ時に発生）
            if (error as NSError).code == NSURLErrorCancelled {
                print("Chat loading was cancelled")
            } else {
                print("Error loading chats: \(error)")
                handleError(error)
            }
        }
        isLoading = false
    }
    
    func sendMessage(_ message: String, image: UIImage? = nil) async {
        do {
            var imageId: String? = nil
            
            // 画像がある場合はアップロード
            if let image = image {
                imageId = try await uploadChatImage(image: image)
            }
            
            let chat = BookChat.new(
                bookId: book.id,
                message: message,
                imageId: imageId
            )
            
            let newChat = try await repository.addChat(chat, bookId: book.id)
            chats.append(newChat)
            
            // アクティビティを記録（メモ作成）
            try? await activityRepository.recordMemoWritten()
            
            // AI応答を生成（有効な場合のみ）
            if isAIEnabled && !message.isEmpty {
                await generateAIResponse(for: message)
            }
        } catch {
            handleError(error)
        }
    }
    
    private func uploadChatImage(image: UIImage) async throws -> String {
        let storageService = StorageService.shared
        // 500KB以下に確実に圧縮してアップロード
        return try await storageService.uploadImage(image, maxFileSizeKB: 500)
    }
    
    func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func generateAIResponse(for message: String) async {
        do {
            // AI応答を生成（サーバー側で保存される）
            let aiResponse = try await aiService.generateAIResponse(
                bookId: book.id,
                message: message
            )
            
            // AI応答のチャットオブジェクトを作成
            let aiChat = BookChat(
                id: UUID().uuidString, // 一時的なID
                bookId: book.id,
                message: aiResponse,
                messageType: .ai,
                imageId: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // AIのチャットをリストに追加
            chats.append(aiChat)
        } catch {
            // AI応答のエラーは静かに処理（ユーザーのチャット体験を妨げない）
            print("AI response error: \(error)")
        }
    }
    
    func toggleAI() {
        // この関数は使わなくなったため、削除または非推奨にすることを推奨
        // ChatContentViewで直接制御するようになりました
    }
    
    
    func deleteChat(_ chat: BookChat) async {
        do {
            try await repository.deleteChat(
                chatId: chat.id,
                bookId: book.id
            )
            
            chats.removeAll { $0.id == chat.id }
        } catch {
            handleError(error)
        }
    }
}
