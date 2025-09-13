import SwiftUI
import PhotosUI

@Observable
class OnboardingViewModel {
    var displayName = ""
    var profileImage: UIImage?
    var selectedGenres: Set<BookGenre> = []
    var monthlyGoal = 3
    var firstBook: Book?
    var firstBookSearchResult: BookSearchResult?
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
                favoriteGenres: Array(selectedGenres).map { $0.rawValue },
                monthlyGoal: monthlyGoal,
                avatarImageId: avatarImageId,
                bio: nil
            )
            
            // 3. First book is already registered via BookSearchView/BarcodeScannerView
            // No need to register it again here
            
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
        // プロフィール画像用の専用メソッドを使用（正方形クロップ + 圧縮）
        return try await storageService.uploadProfileImage(image)
    }
}
