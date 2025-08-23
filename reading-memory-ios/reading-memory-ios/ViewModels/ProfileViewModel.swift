import Foundation
// import FirebaseAuth
import PhotosUI
import SwiftUI

@Observable
final class ProfileViewModel: BaseViewModel {
    private let userProfileRepository = UserProfileRepository.shared
    private let bookRepository = BookRepository.shared
    private let bookChatRepository = BookChatRepository.shared
    
    var userProfile: UserProfile?
    var statistics: ProfileStatistics = ProfileStatistics()
    var isEditMode = false
    var selectedPhoto: PhotosPickerItem?
    var profileImage: UIImage?
    
    // Edit form properties
    var editDisplayName = ""
    var editBio = ""
    var editFavoriteGenres: [String] = []
    var editReadingGoal: String = ""
    var editIsPublic = false
    
    // キャッシュされたデータ
    private var cachedBooks: [Book] = []
    
    struct ProfileStatistics {
        var totalBooks: Int = 0
        var completedBooks: Int = 0
        var readingBooks: Int = 0
        var wantToReadBooks: Int = 0
        var totalMemos: Int = 0
        var averageRating: Double = 0.0
        var favoriteGenres: [String] = []
        var readingStreak: Int = 0
        var booksThisMonth: Int = 0
        var booksThisYear: Int = 0
    }
    
    override init() {
        super.init()
    }
    
    @MainActor
    func loadProfile() async {
        await executeLoadTask { [weak self] in
            guard let self = self else { return }
            // 初回読み込みまたはキャッシュ期限切れの場合のみデータを取得
            if self.shouldRefreshData() {
                await self.fetchAndCacheData()
            }
        }
    }
    
    @MainActor
    private func fetchAndCacheData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = await AuthService.shared.currentUser?.uid else {
                throw AppError.authenticationRequired
            }
            
            // Load user profile
            userProfile = try await userProfileRepository.getUserProfile()
            
            // If profile doesn't exist, create one
            if userProfile == nil {
                if let currentUser = await AuthService.shared.currentUser {
                    let user = User(
                        id: currentUser.uid,
                        email: currentUser.email ?? "",
                        displayName: currentUser.displayName ?? "",
                        photoURL: currentUser.photoURL?.absoluteString,
                        provider: .email, // Default provider for dummy implementation
                        createdAt: Date(), // Use current date for dummy
                        lastLoginAt: Date() // Use current date for dummy
                    )
                    userProfile = try await userProfileRepository.createInitialProfile(for: user)
                }
            }
            
            // ユーザーの本を取得してキャッシュ
            cachedBooks = try await bookRepository.getBooks()
            
            // Load statistics
            await loadStatistics()
            
            // Initialize edit form
            if let profile = userProfile {
                editDisplayName = profile.displayName
                editBio = profile.bio ?? ""
                editFavoriteGenres = profile.favoriteGenres
                editReadingGoal = profile.readingGoal != nil ? String(profile.readingGoal!) : ""
                editIsPublic = profile.isPublic
            }
            
            // データ取得完了をマーク
            markDataAsFetched()
            
        } catch {
            errorMessage = AppError.from(error).localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadStatistics() async {
        do {
            // キャッシュされたデータを使用
            let books = cachedBooks
            
            // Calculate basic statistics
            statistics.totalBooks = books.count
            statistics.completedBooks = books.filter { $0.status == .completed }.count
            statistics.readingBooks = books.filter { $0.status == .reading }.count
            statistics.wantToReadBooks = books.filter { $0.status == .wantToRead }.count
            
            // Calculate average rating
            let ratedBooks = books.filter { $0.rating != nil && $0.rating! > 0 }
            if !ratedBooks.isEmpty {
                let totalRating = ratedBooks.reduce(0.0) { sum, book in sum + Double(book.rating!) }
                statistics.averageRating = totalRating / Double(ratedBooks.count)
            }
            
            // Calculate books this month and year
            let now = Date()
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            
            statistics.booksThisMonth = books.filter { book in
                guard let completedDate = book.completedDate else { return false }
                let bookMonth = calendar.component(.month, from: completedDate)
                let bookYear = calendar.component(.year, from: completedDate)
                return bookMonth == currentMonth && bookYear == currentYear
            }.count
            
            statistics.booksThisYear = books.filter { book in
                guard let completedDate = book.completedDate else { return false }
                let bookYear = calendar.component(.year, from: completedDate)
                return bookYear == currentYear
            }.count
            
            // Count total memos (遅延読み込み、表示時には必要ないためスキップ)
            // ユーザーがプロフィールを表示したときのみメモ数を取得
            statistics.totalMemos = 0  // デフォルトは0
            
            // Extract favorite genres from user profile
            if let profile = userProfile {
                statistics.favoriteGenres = profile.favoriteGenres
            }
            
        } catch {
            print("Error loading statistics: \(error)")
        }
    }
    
    @MainActor
    func startEditing() {
        isEditMode = true
    }
    
    @MainActor
    func cancelEditing() {
        isEditMode = false
        selectedPhoto = nil
        profileImage = nil
        
        // Reset edit form
        if let profile = userProfile {
            editDisplayName = profile.displayName
            editBio = profile.bio ?? ""
            editFavoriteGenres = profile.favoriteGenres
            editReadingGoal = profile.readingGoal != nil ? String(profile.readingGoal!) : ""
            editIsPublic = profile.isPublic
        }
    }
    
    @MainActor
    func saveProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let profile = userProfile else {
                throw AppError.dataNotFound
            }
            
            // Upload profile image if selected
            var profileImageUrl = profile.profileImageUrl
            if let selectedPhoto = selectedPhoto {
                profileImageUrl = try await uploadProfileImage(selectedPhoto: selectedPhoto, userId: profile.id)
            }
            
            // Update profile
            let updatedProfile = UserProfile(
                id: profile.id,
                displayName: editDisplayName.isEmpty ? profile.displayName : editDisplayName,
                profileImageUrl: profileImageUrl,
                bio: editBio.isEmpty ? nil : editBio,
                favoriteGenres: editFavoriteGenres,
                readingGoal: Int(editReadingGoal),
                isPublic: editIsPublic,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )
            
            try await userProfileRepository.updateUserProfile(updatedProfile)
            userProfile = updatedProfile
            
            // キャッシュを無効化して次回読み込み時に最新データを取得
            forceRefresh()
            
            isEditMode = false
            selectedPhoto = nil
            profileImage = nil
            
        } catch {
            errorMessage = AppError.from(error).localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func uploadProfileImage(selectedPhoto: PhotosPickerItem, userId: String) async throws -> String {
        guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            throw AppError.imageUploadFailed
        }
        
        let storageService = StorageService.shared
        return try await storageService.uploadImage(
            image,
            path: .profileImage(userId: userId)
        )
    }
    
    @MainActor
    func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                profileImage = UIImage(data: data)
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
    
    func addGenre(_ genre: String) {
        let trimmedGenre = genre.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedGenre.isEmpty && !editFavoriteGenres.contains(trimmedGenre) {
            editFavoriteGenres.append(trimmedGenre)
        }
    }
    
    func removeGenre(_ genre: String) {
        editFavoriteGenres.removeAll { $0 == genre }
    }
}