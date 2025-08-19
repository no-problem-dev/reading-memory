import Foundation
import FirebaseAuth
import FirebaseStorage
import PhotosUI
import SwiftUI

@Observable
final class ProfileViewModel: BaseViewModel {
    private let userProfileRepository = UserProfileRepository.shared
    private let userBookRepository = UserBookRepository.shared
    private let bookChatRepository = BookChatRepository.shared
    private let storage = Storage.storage()
    
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
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw AppError.authenticationRequired
            }
            
            // Load user profile
            userProfile = try await userProfileRepository.getUserProfile(userId: userId)
            
            // If profile doesn't exist, create one
            if userProfile == nil {
                if let currentUser = Auth.auth().currentUser {
                    let user = User(
                        id: currentUser.uid,
                        email: currentUser.email ?? "",
                        displayName: currentUser.displayName ?? "",
                        photoURL: currentUser.photoURL?.absoluteString,
                        provider: User.AuthProvider(providerId: currentUser.providerData.first?.providerID ?? ""),
                        createdAt: currentUser.metadata.creationDate ?? Date(),
                        lastLoginAt: currentUser.metadata.lastSignInDate ?? Date()
                    )
                    userProfile = try await userProfileRepository.createInitialProfile(for: user)
                }
            }
            
            // Load statistics
            await loadStatistics(userId: userId)
            
            // Initialize edit form
            if let profile = userProfile {
                editDisplayName = profile.displayName
                editBio = profile.bio ?? ""
                editFavoriteGenres = profile.favoriteGenres
                editReadingGoal = profile.readingGoal != nil ? String(profile.readingGoal!) : ""
                editIsPublic = profile.isPublic
            }
            
        } catch {
            errorMessage = AppError.from(error).localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadStatistics(userId: String) async {
        do {
            // Get all user books
            let userBooks = try await userBookRepository.getUserBooks(for: userId)
            
            // Calculate basic statistics
            statistics.totalBooks = userBooks.count
            statistics.completedBooks = userBooks.filter { $0.status == .completed }.count
            statistics.readingBooks = userBooks.filter { $0.status == .reading }.count
            statistics.wantToReadBooks = userBooks.filter { $0.status == .wantToRead }.count
            
            // Calculate average rating
            let ratedBooks = userBooks.filter { $0.rating != nil && $0.rating! > 0 }
            if !ratedBooks.isEmpty {
                let totalRating = ratedBooks.reduce(0.0) { sum, book in sum + Double(book.rating!) }
                statistics.averageRating = totalRating / Double(ratedBooks.count)
            }
            
            // Calculate books this month and year
            let now = Date()
            let calendar = Calendar.current
            let currentMonth = calendar.component(.month, from: now)
            let currentYear = calendar.component(.year, from: now)
            
            statistics.booksThisMonth = userBooks.filter { book in
                guard let completedDate = book.completedDate else { return false }
                let bookMonth = calendar.component(.month, from: completedDate)
                let bookYear = calendar.component(.year, from: completedDate)
                return bookMonth == currentMonth && bookYear == currentYear
            }.count
            
            statistics.booksThisYear = userBooks.filter { book in
                guard let completedDate = book.completedDate else { return false }
                let bookYear = calendar.component(.year, from: completedDate)
                return bookYear == currentYear
            }.count
            
            // Count total memos
            var totalMemoCount = 0
            for userBook in userBooks {
                let memos = try await bookChatRepository.getChats(userId: userId, userBookId: userBook.id, limit: 1000)
                totalMemoCount += memos.count
            }
            statistics.totalMemos = totalMemoCount
            
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
        guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else {
            throw AppError.imageUploadFailed
        }
        
        // Create a reference to the file
        let imageName = "\(userId)_\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("profile_images/\(imageName)")
        
        // Upload the file
        let _ = try await storageRef.putDataAsync(data)
        
        // Get the download URL
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
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