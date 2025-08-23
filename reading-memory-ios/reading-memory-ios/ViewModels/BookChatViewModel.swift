import Foundation
// TODO: Remove Firebase dependency
// import FirebaseFirestore
// import FirebaseAuth
// import FirebaseStorage
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
    private var listener: ListenerRegistration?
    
    var isAIEnabled = false // AI機能の有効/無効フラグ
    
    init(book: Book) {
        self.book = book
        super.init()
    }
    
    func loadChats() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self else { return }
            
            self.chats = try await self.repository.getChats(
                bookId: self.book.id
            )
        }
    }
    
    func sendMessage(_ message: String, image: UIImage? = nil) async {
        do {
            var imageUrl: String? = nil
            
            // 画像がある場合はアップロード
            if let image = image {
                imageUrl = try await uploadChatImage(image: image)
            }
            
            let chat = BookChat.new(
                bookId: book.id,
                message: message,
                imageUrl: imageUrl
            )
            
            let newChat = try await repository.addChat(chat)
            // リアルタイム同期がある場合は手動追加しない
            if listener == nil {
                chats.append(newChat)
            }
            
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
        let photoId = UUID().uuidString
        
        return try await storageService.uploadImage(
            image,
            path: .chatPhoto(bookId: book.id, photoId: photoId)
        )
    }
    
    func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func generateAIResponse(for message: String) async {
        do {
            // AI応答を生成
            _ = try await aiService.generateAIResponse(
                bookId: book.id,
                message: message
            )
            
            // AIのチャットはFirestoreから自動的に同期される
            // ここでは何もしない（リアルタイムリスナーが更新を処理）
        } catch {
            // AI応答のエラーは静かに処理（ユーザーのチャット体験を妨げない）
            print("AI response error: \(error)")
        }
    }
    
    func toggleAI() {
        isAIEnabled.toggle()
    }
    
    func startListening() {
        listener = repository.listenToChats(
            bookId: book.id
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let chats):
                    self?.chats = chats
                case .failure(let error):
                    self?.handleError(error)
                }
            }
        }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func deleteChat(_ chat: BookChat) async {
        do {
            try await repository.deleteChat(
                chatId: chat.id,
                bookId: book.id
            )
            
            // リアルタイム同期がない場合は手動で削除
            if listener == nil {
                chats.removeAll { $0.id == chat.id }
            }
        } catch {
            handleError(error)
        }
    }
}
