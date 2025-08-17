import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
@Observable
final class BookChatViewModel: BaseViewModel {
    var chats: [BookChat] = []
    
    let userBook: UserBook
    private let repository = BookChatRepository.shared
    private let authService = AuthService.shared
    private var listener: ListenerRegistration?
    
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
    
    func sendMessage(_ message: String) async {
        guard let userId = authService.currentUser?.uid else {
            handleError(AppError.authenticationRequired)
            return
        }
        
        let chat = BookChat(
            userBookId: userBook.id,
            userId: userId,
            message: message
        )
        
        do {
            let newChat = try await repository.addChat(chat, userId: userId)
            // リアルタイム同期がある場合は手動追加しない
            if listener == nil {
                chats.append(newChat)
            }
        } catch {
            handleError(error)
        }
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
}
