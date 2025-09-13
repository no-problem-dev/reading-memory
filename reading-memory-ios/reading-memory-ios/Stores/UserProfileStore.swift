import Foundation
import SwiftUI

/// アプリ全体のユーザープロフィール状態を管理する環境オブジェクト
/// Single Source of Truthとして機能し、プロフィール関連の操作を一元管理
@MainActor
@Observable
final class UserProfileStore {
    // MARK: - Properties
    
    /// 現在のユーザープロフィール
    private(set) var userProfile: UserProfile?
    
    /// プロフィール統計情報
    private(set) var statistics: ProfileStatistics = ProfileStatistics()
    
    /// ローディング状態
    private(set) var isLoading = false
    
    /// エラー
    private(set) var error: Error?
    
    /// キャッシュの有効期限（5分）
    private let cacheExpiry: TimeInterval = 300
    
    /// 最後のデータ取得時刻
    private var lastFetchTime: Date?
    
    // MARK: - Dependencies
    
    private let userProfileRepository: UserProfileRepository
    private let bookRepository: BookRepository
    private let bookChatRepository: BookChatRepository
    private let authService = AuthService.shared
    
    // MARK: - Initialization
    
    init(
        userProfileRepository: UserProfileRepository = UserProfileRepository.shared,
        bookRepository: BookRepository = BookRepository.shared,
        bookChatRepository: BookChatRepository = BookChatRepository.shared
    ) {
        self.userProfileRepository = userProfileRepository
        self.bookRepository = bookRepository
        self.bookChatRepository = bookChatRepository
    }
    
    // MARK: - Public Methods
    
    /// プロフィールを読み込む
    func loadProfile() async {
        // キャッシュが有効な場合はスキップ
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheExpiry,
           userProfile != nil {
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            guard authService.currentUser?.uid != nil else {
                throw AppError.authenticationRequired
            }
            
            // プロフィールを取得
            userProfile = try await userProfileRepository.getUserProfile()
            
            // プロフィールが存在しない場合は作成
            if userProfile == nil {
                userProfile = try await createInitialProfile()
            }
            
            // 統計情報を更新
            await updateStatistics()
            
            lastFetchTime = Date()
        } catch {
            self.error = error
            print("Error loading profile: \(error)")
        }
        
        isLoading = false
    }
    
    /// プロフィールを更新
    func updateProfile(_ profile: UserProfile) async throws {
        try await userProfileRepository.updateUserProfile(profile)
        userProfile = profile
        
        // 統計情報も更新
        await updateStatistics()
    }
    
    /// プロフィール画像を更新
    func updateProfileImage(_ imageData: Data) async throws -> String {
        guard let image = UIImage(data: imageData) else {
            throw AppError.imageUploadFailed
        }
        
        let storageService = StorageService.shared
        let imageId = try await storageService.uploadProfileImage(image)
        
        // プロフィールを更新
        if let profile = userProfile {
            let updatedProfile = UserProfile(
                id: profile.id,
                displayName: profile.displayName,
                avatarImageId: imageId,
                bio: profile.bio,
                favoriteGenres: profile.favoriteGenres,
                readingGoal: profile.readingGoal,
                monthlyGoal: profile.monthlyGoal,
                streakStartDate: profile.streakStartDate,
                longestStreak: profile.longestStreak,
                currentStreak: profile.currentStreak,
                lastActivityDate: profile.lastActivityDate,
                isPublic: profile.isPublic,
                createdAt: profile.createdAt,
                updatedAt: Date()
            )
            try await updateProfile(updatedProfile)
        }
        
        return imageId
    }
    
    /// 読書目標を更新
    func updateReadingGoal(yearly: Int?, monthly: Int?) async throws {
        guard let profile = userProfile else {
            throw AppError.dataNotFound
        }
        
        let updatedProfile = UserProfile(
            id: profile.id,
            displayName: profile.displayName,
            avatarImageId: profile.avatarImageId,
            bio: profile.bio,
            favoriteGenres: profile.favoriteGenres,
            readingGoal: yearly,
            monthlyGoal: monthly,
            streakStartDate: profile.streakStartDate,
            longestStreak: profile.longestStreak,
            currentStreak: profile.currentStreak,
            lastActivityDate: profile.lastActivityDate,
            isPublic: profile.isPublic,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
        
        try await updateProfile(updatedProfile)
    }
    
    /// キャッシュを強制的にリフレッシュ
    func forceRefresh() async {
        lastFetchTime = nil
        await loadProfile()
    }
    
    // MARK: - Private Methods
    
    /// 初期プロフィールを作成
    private func createInitialProfile() async throws -> UserProfile {
        guard let currentUser = authService.currentUser else {
            throw AppError.authenticationRequired
        }
        
        let user = User(
            id: currentUser.uid,
            email: currentUser.email ?? "",
            displayName: currentUser.displayName ?? "",
            photoURL: currentUser.photoURL?.absoluteString,
            provider: .email,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        return try await userProfileRepository.createInitialProfile(for: user)
    }
    
    /// 統計情報を更新
    private func updateStatistics() async {
        do {
            // 本のデータを取得
            let books = try await bookRepository.getBooks()
            
            // 基本統計
            statistics.totalBooks = books.count
            statistics.completedBooks = books.filter { $0.status == .completed }.count
            statistics.readingBooks = books.filter { $0.status == .reading }.count
            statistics.wantToReadBooks = books.filter { $0.status == .wantToRead }.count
            
            // 平均評価
            let ratedBooks = books.filter { $0.rating != nil && $0.rating! > 0 }
            if !ratedBooks.isEmpty {
                let totalRating = ratedBooks.reduce(0.0) { sum, book in sum + Double(book.rating!) }
                statistics.averageRating = totalRating / Double(ratedBooks.count)
            }
            
            // 今月・今年の本
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
            
            // お気に入りジャンル
            if let profile = userProfile {
                statistics.favoriteGenres = profile.favoriteGenres
                statistics.readingStreak = profile.currentStreak
            }
            
            // メモ数（必要に応じて遅延取得）
            statistics.totalMemos = 0
            
        } catch {
            print("Error updating statistics: \(error)")
        }
    }
}

// MARK: - Supporting Types

extension UserProfileStore {
    struct ProfileStatistics {
        var totalBooks: Int = 0
        var completedBooks: Int = 0
        var readingBooks: Int = 0
        var wantToReadBooks: Int = 0
        var totalMemos: Int = 0
        var averageRating: Double = 0.0
        var favoriteGenres: [BookGenre] = []
        var readingStreak: Int = 0
        var booksThisMonth: Int = 0
        var booksThisYear: Int = 0
    }
}