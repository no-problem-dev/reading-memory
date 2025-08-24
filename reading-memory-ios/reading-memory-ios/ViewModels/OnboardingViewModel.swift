import SwiftUI
import PhotosUI
// import FirebaseStorage

@Observable
class OnboardingViewModel {
    var displayName = ""
    var profileImage: UIImage?
    var selectedGenres: Set<String> = []
    var monthlyGoal = 3
    var firstBook: Book?
    var isLoading = false
    var errorMessage: String?
    
    var authViewModel: AuthViewModel
    private let userProfileRepository = UserProfileRepository.shared
    private let bookRepository = BookRepository.shared
    private let goalRepository = GoalRepository.shared
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    @MainActor
    func completeOnboarding() async -> Bool {
        guard let currentUser = authViewModel.currentUser else {
            errorMessage = "ユーザー情報が見つかりません"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Upload profile image if exists
            var avatarImageId: String?
            if let profileImage = profileImage {
                avatarImageId = try await uploadProfileImage(image: profileImage)
            }
            
            // 2. Complete onboarding through unified API
            let apiClient = APIClient.shared
            _ = try await apiClient.completeOnboarding(
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                favoriteGenres: Array(selectedGenres),
                monthlyGoal: monthlyGoal,
                avatarImageId: avatarImageId,
                bio: nil
            )
            
            // 3. Add first book if selected
            if let selectedBook = firstBook {
                let book = Book(
                    id: UUID().uuidString,
                    isbn: selectedBook.isbn,
                    title: selectedBook.title,
                    author: selectedBook.author,
                    publisher: selectedBook.publisher,
                    publishedDate: selectedBook.publishedDate,
                    pageCount: selectedBook.pageCount,
                    description: selectedBook.description,
                    coverImageId: selectedBook.coverImageId,
                    dataSource: selectedBook.dataSource,
                    status: .reading,
                    rating: nil,
                    readingProgress: nil,
                    currentPage: nil,
                    addedDate: Date(),
                    startDate: Date(),
                    completedDate: nil,
                    lastReadDate: nil,
                    priority: nil,
                    plannedReadingDate: nil,
                    reminderEnabled: false,
                    purchaseLinks: nil,
                    memo: nil,
                    tags: [],
                    aiSummary: nil,
                    summaryGeneratedAt: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                _ = try await bookRepository.createBook(book)
            }
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = AppError.from(error).localizedDescription
            isLoading = false
            return false
        }
    }
    
    private func uploadProfileImage(image: UIImage) async throws -> String {
        let storageService = StorageService.shared
        return try await storageService.uploadImage(image)
    }
}