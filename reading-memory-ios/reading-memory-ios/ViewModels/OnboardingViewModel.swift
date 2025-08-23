import SwiftUI
import PhotosUI
import FirebaseStorage

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
    private let userBookRepository = UserBookRepository.shared
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
            var profileImageUrl: String?
            if let profileImage = profileImage {
                profileImageUrl = try await uploadProfileImage(
                    image: profileImage,
                    userId: currentUser.id
                )
            }
            
            // 2. Create user profile
            let profile = UserProfile(
                id: currentUser.id,
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                profileImageUrl: profileImageUrl,
                bio: nil,
                favoriteGenres: Array(selectedGenres),
                readingGoal: monthlyGoal,
                isPublic: false
            )
            
            _ = try await userProfileRepository.createUserProfile(profile)
            
            // 3. Create monthly reading goal
            let goal = ReadingGoal.createMonthlyGoal(
                userId: currentUser.id,
                targetBooks: monthlyGoal
            )
            
            try await goalRepository.createGoal(goal)
            
            // 4. Add first book if selected
            if let book = firstBook {
                let userBook = UserBook(
                    id: UUID().uuidString,
                    userId: currentUser.id,
                    bookTitle: book.title,
                    bookAuthor: book.author,
                    bookCoverImageUrl: book.coverImageUrl,
                    bookIsbn: book.isbn,
                    status: .reading,
                    tags: [],
                    isPrivate: false,
                    reminderEnabled: false,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                _ = try await userBookRepository.createUserBook(userBook)
            }
            
            isLoading = false
            return true
            
        } catch {
            errorMessage = AppError.from(error).localizedDescription
            isLoading = false
            return false
        }
    }
    
    private func uploadProfileImage(image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AppError.imageUploadFailed
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await profileImageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await profileImageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
}