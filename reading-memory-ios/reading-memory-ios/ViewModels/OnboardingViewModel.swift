import SwiftUI
import PhotosUI
// import FirebaseStorage

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
                favoriteGenres: Array(selectedGenres).map { $0.rawValue },
                monthlyGoal: monthlyGoal,
                avatarImageId: avatarImageId,
                bio: nil
            )
            
            // 3. Add first book if selected
            if let searchResult = firstBookSearchResult {
                // 検索結果から本を作成（画像のアップロードを含む）
                _ = try await bookRepository.createBookFromSearchResult(searchResult)
            } else if let selectedBook = firstBook {
                // 既存の本を保存
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
        // 500KB以下に圧縮
        guard let compressedData = image.compressedJPEGData(maxFileSizeKB: 500) else {
            throw AppError.custom("画像の圧縮に失敗しました")
        }
        
        guard let compressedImage = UIImage(data: compressedData) else {
            throw AppError.custom("圧縮データから画像を作成できませんでした")
        }
        
        let storageService = StorageService.shared
        return try await storageService.uploadImage(compressedImage)
    }
}

// MARK: - UIImage Extension
private extension UIImage {
    /// 指定されたファイルサイズ以下になるまで画像を圧縮
    /// - Parameters:
    ///   - maxFileSizeKB: 最大ファイルサイズ（KB単位）
    ///   - initialQuality: 初期圧縮品質（0.0〜1.0）
    /// - Returns: 圧縮されたJPEGデータ
    func compressedJPEGData(maxFileSizeKB: Int = 500, initialQuality: CGFloat = 0.8) -> Data? {
        let maxFileSize = maxFileSizeKB * 1024 // KBをバイトに変換
        
        // 最初に指定品質で圧縮を試みる
        if let data = self.jpegData(compressionQuality: initialQuality),
           data.count <= maxFileSize {
            return data
        }
        
        // 品質を段階的に下げる
        let qualities: [CGFloat] = [0.7, 0.5, 0.3, 0.2, 0.1]
        for quality in qualities {
            if let data = self.jpegData(compressionQuality: quality),
               data.count <= maxFileSize {
                return data
            }
        }
        
        // それでも大きい場合は、画像サイズを縮小してから圧縮
        let scales: [(CGFloat, CGFloat)] = [(0.8, 0.5), (0.6, 0.4), (0.4, 0.3), (0.3, 0.2)]
        for (scale, quality) in scales {
            let newSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
            let resizedImage = self.resized(to: newSize)
            if let data = resizedImage.jpegData(compressionQuality: quality),
               data.count <= maxFileSize {
                return data
            }
        }
        
        // 最終手段：最小サイズ・最低品質
        let minSize = CGSize(width: 200, height: 200)
        let minImage = self.resized(to: minSize)
        let finalData = minImage.jpegData(compressionQuality: 0.1)
        return finalData
    }
    
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}