import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

@MainActor
@Observable
final class BookChatViewModel: BaseViewModel {
    var chats: [BookChat] = []
    
    let userBook: UserBook
    private let repository = BookChatRepository.shared
    private let authService = AuthService.shared
    private let aiService = AIService.shared
    private let activityRepository = ActivityRepository.shared
    private var listener: ListenerRegistration?
    
    var isAIEnabled = false // AI機能の有効/無効フラグ
    
    init(userBook: UserBook) {
        self.userBook = userBook
        super.init()
    }
    
    func loadChats() async {
        await withLoadingNoThrow { [weak self] in
            guard let self = self,
                  let userId = self.authService.currentUser?.uid else {
                throw AppError.authenticationRequired
            }
            
            self.chats = try await self.repository.getChats(
                userId: userId,
                userBookId: self.userBook.id
            )
        }
    }
    
    func sendMessage(_ message: String, image: UIImage? = nil) async {
        guard let userId = authService.currentUser?.uid else {
            handleError(AppError.authenticationRequired)
            return
        }
        
        do {
            var imageUrl: String? = nil
            
            // 画像がある場合はアップロード
            if let image = image {
                imageUrl = try await uploadChatImage(image: image, userId: userId)
            }
            
            let chat = BookChat.new(
                userBookId: userBook.id,
                userId: userId,
                message: message,
                imageUrl: imageUrl
            )
            
            let newChat = try await repository.addChat(chat, userId: userId)
            // リアルタイム同期がある場合は手動追加しない
            if listener == nil {
                chats.append(newChat)
            }
            
            // アクティビティを記録（メモ作成）
            try? await activityRepository.recordMemoWritten(userId: userId)
            
            // AI応答を生成（有効な場合のみ）
            if isAIEnabled && !message.isEmpty {
                await generateAIResponse(for: message, userId: userId)
            }
        } catch {
            handleError(error)
        }
    }
    
    private func uploadChatImage(image: UIImage, userId: String) async throws -> String {
        let storageService = StorageService.shared
        let photoId = UUID().uuidString
        
        return try await storageService.uploadImage(
            image,
            path: .chatPhoto(userId: userId, bookId: userBook.id, photoId: photoId)
        )
    }
    
    func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func generateAIResponse(for message: String, userId: String) async {
        do {
            // AI応答を生成
            _ = try await aiService.generateAIResponse(
                userId: userId,
                userBookId: userBook.id,
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
        guard let userId = authService.currentUser?.uid else {
            handleError(AppError.authenticationRequired)
            return
        }
        
        listener = repository.listenToChats(
            userId: userId,
            userBookId: userBook.id
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
        guard let userId = authService.currentUser?.uid else {
            handleError(AppError.authenticationRequired)
            return
        }
        
        do {
            try await repository.deleteChat(
                chatId: chat.id,
                userId: userId,
                userBookId: userBook.id
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
