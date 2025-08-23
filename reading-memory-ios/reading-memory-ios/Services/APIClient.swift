import Foundation

/// REST APIクライアント
final class APIClient {
    static let shared = APIClient()
    
    private let baseURL: String
    private let session: URLSession
    
    private init() {
        self.baseURL = Config.shared.apiBaseURL
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Request Methods
    
    private func makeRequest(
        method: String,
        path: String,
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> URLRequest {
        var components = URLComponents(string: baseURL + path)!
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw AppError.custom("無効なURLです")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Firebase IDトークンを取得して設定
        let authService = await AuthService.shared
        if let user = await authService.currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("DEBUG: Setting authorization header with token length: \(token.count)")
        } else {
            print("DEBUG: No current user found for authorization")
        }
        
        request.httpBody = body
        
        return request
    }
    
    private func execute<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.custom("無効なレスポンスです")
        }
        
        if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
            do {
                let decoder = JSONDecoder()
                
                // Custom ISO8601 date formatter that handles milliseconds
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // Try with milliseconds first
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Try without milliseconds
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Try basic ISO8601
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = isoFormatter.date(from: dateString) {
                        return date
                    }
                    
                    // Try without fractional seconds
                    isoFormatter.formatOptions = [.withInternetDateTime]
                    if let date = isoFormatter.date(from: dateString) {
                        return date
                    }
                    
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Cannot decode date string \(dateString)"
                    )
                }
                
                return try decoder.decode(T.self, from: data)
            } catch {
                // デバッグ用: レスポンスの内容を出力
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Failed to decode response for \(T.self): \(responseString)")
                }
                print("DEBUG: Decoding error: \(error)")
                throw AppError.custom("レスポンスの解析に失敗しました")
            }
        } else {
            // エラーレスポンスの解析
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw AppError.custom(errorResponse.error.message)
            } else {
                throw AppError.custom("サーバーエラーが発生しました (\(httpResponse.statusCode))")
            }
        }
    }
    
    // MARK: - Public Methods
    
    // MARK: Auth関連
    
    func initializeUser() async throws -> InitializeUserResult {
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/auth/initialize"
        )
        
        return try await execute(request, responseType: InitializeUserResult.self)
    }
    
    func getOnboardingStatus() async throws -> OnboardingStatus {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/auth/onboarding-status"
        )
        
        return try await execute(request, responseType: OnboardingStatus.self)
    }
    
    func completeOnboarding(displayName: String, favoriteGenres: [String], monthlyGoal: Int, profileImageUrl: String? = nil, bio: String? = nil) async throws -> OnboardingResult {
        var body: [String: Any] = [
            "displayName": displayName,
            "favoriteGenres": favoriteGenres,
            "monthlyGoal": monthlyGoal
        ]
        
        if let profileImageUrl = profileImageUrl {
            body["profileImageUrl"] = profileImageUrl
        }
        
        if let bio = bio {
            body["bio"] = bio
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/auth/complete-onboarding",
            body: jsonData
        )
        
        return try await execute(request, responseType: OnboardingResult.self)
    }
    
    // MARK: AI関連
    
    func generateAIResponse(bookId: String, message: String) async throws -> AIResponseResult {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode([
            "message": message
        ])
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/books/\(bookId)/ai-response",
            body: body
        )
        
        return try await execute(request, responseType: AIResponseResult.self)
    }
    
    func generateBookSummary(bookId: String) async throws -> SummaryResult {
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/books/\(bookId)/summary"
        )
        
        return try await execute(request, responseType: SummaryResult.self)
    }
    
    // MARK: 書籍検索
    
    func searchBookByISBN(_ isbn: String) async throws -> BookSearchResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/books/search/isbn/\(isbn)"
        )
        
        return try await execute(request, responseType: BookSearchResult.self)
    }
    
    func searchBooksByQuery(_ query: String) async throws -> BookSearchResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/books/search",
            queryItems: [URLQueryItem(name: "q", value: query)]
        )
        
        return try await execute(request, responseType: BookSearchResult.self)
    }
    
    // MARK: 公開本
    
    func getPopularBooks(limit: Int = 20) async throws -> PublicBooksResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/public/books/popular",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
        
        return try await execute(request, responseType: PublicBooksResult.self)
    }
    
    func getRecentBooks(limit: Int = 20) async throws -> PublicBooksResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/public/books/recent",
            queryItems: [URLQueryItem(name: "limit", value: String(limit))]
        )
        
        return try await execute(request, responseType: PublicBooksResult.self)
    }
    
    func searchPublicBooks(query: String, limit: Int = 20) async throws -> PublicBooksResult {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/public/books/search",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        )
        
        return try await execute(request, responseType: PublicBooksResult.self)
    }
    
    // MARK: アカウント管理
    
    func deleteAccount() async throws -> DeleteAccountResult {
        let request = try await makeRequest(
            method: "DELETE",
            path: "/api/v1/users/me"
        )
        
        return try await execute(request, responseType: DeleteAccountResult.self)
    }
    
    // MARK: - Books CRUD
    
    func getBooks() async throws -> [Book] {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/books"
        )
        
        let response = try await execute(request, responseType: BooksResponse.self)
        return response.books.map { $0.toDomain() }
    }
    
    func getBook(id: String) async throws -> Book {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/books/\(id)"
        )
        
        let response = try await execute(request, responseType: BookResponse.self)
        return response.book.toDomain()
    }
    
    func createBook(_ book: Book) async throws -> Book {
        let bookData = BookCreateRequest(from: book)
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode(bookData)
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/books",
            body: body
        )
        
        let response = try await execute(request, responseType: BookResponse.self)
        return response.book.toDomain()
    }
    
    func updateBook(_ book: Book) async throws -> Book {
        let bookData = BookUpdateRequest(from: book)
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode(bookData)
        
        let request = try await makeRequest(
            method: "PUT",
            path: "/api/v1/books/\(book.id)",
            body: body
        )
        
        let response = try await execute(request, responseType: BookResponse.self)
        return response.book.toDomain()
    }
    
    func deleteBook(id: String) async throws {
        let request = try await makeRequest(
            method: "DELETE",
            path: "/api/v1/books/\(id)"
        )
        
        _ = try await execute(request, responseType: EmptyResponse.self)
    }
    
    // MARK: - Activities
    
    func getActivities() async throws -> [ReadingActivity] {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/activities"
        )
        
        let response = try await execute(request, responseType: ActivitiesResponse.self)
        return response.activities.map { $0.toDomain() }
    }
    
    func createActivity(_ activity: ReadingActivity) async throws -> ReadingActivity {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode(activity)
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/activities",
            body: body
        )
        
        let response = try await execute(request, responseType: ActivityResponse.self)
        return response.activity.toDomain()
    }
    
    // MARK: - Goals
    
    func getGoals() async throws -> [ReadingGoal] {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/goals"
        )
        
        let response = try await execute(request, responseType: GoalsResponse.self)
        return response.goals.map { $0.toDomain() }
    }
    
    func createGoal(_ goal: ReadingGoal) async throws -> ReadingGoal {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode(goal)
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/goals",
            body: body
        )
        
        let response = try await execute(request, responseType: GoalResponse.self)
        return response.goal.toDomain()
    }
    
    func updateGoal(_ goal: ReadingGoal) async throws -> ReadingGoal {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode(goal)
        
        let request = try await makeRequest(
            method: "PUT",
            path: "/api/v1/goals/\(goal.id)",
            body: body
        )
        
        let response = try await execute(request, responseType: GoalResponse.self)
        return response.goal.toDomain()
    }
    
    func deleteGoal(id: String) async throws {
        let request = try await makeRequest(
            method: "DELETE",
            path: "/api/v1/goals/\(id)"
        )
        
        _ = try await execute(request, responseType: EmptyResponse.self)
    }
    
    // MARK: - Achievements
    
    func getAchievements() async throws -> [Achievement] {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/achievements"
        )
        
        let response = try await execute(request, responseType: AchievementsResponse.self)
        return response.achievements.map { $0.toDomain() }
    }
    
    func createAchievement(_ achievement: Achievement) async throws -> Achievement {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode(achievement)
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/achievements",
            body: body
        )
        
        let response = try await execute(request, responseType: AchievementResponse.self)
        return response.achievement.toDomain()
    }
    
    // MARK: - Streaks
    
    func getStreaks() async throws -> [ReadingStreak] {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/streaks"
        )
        
        let response = try await execute(request, responseType: StreaksResponse.self)
        return response.streaks.map { $0.toDomain() }
    }
    
    func createOrUpdateStreak(_ streak: ReadingStreak) async throws -> ReadingStreak {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode(streak)
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/streaks",
            body: body
        )
        
        let response = try await execute(request, responseType: StreakResponse.self)
        return response.streak.toDomain()
    }
    
    // MARK: - User Profile
    
    func getUserProfile() async throws -> UserProfile? {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/profile"
        )
        
        do {
            let response = try await execute(request, responseType: UserProfileResponse.self)
            return response.profile
        } catch {
            if let apiError = error as? AppError,
               case .custom(let message) = apiError,
               message.contains("404") {
                return nil
            }
            throw error
        }
    }
    
    func createUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode(profile)
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/profile",
            body: body
        )
        
        let response = try await execute(request, responseType: UserProfileResponse.self)
        return response.profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        let body = try encoder.encode(profile)
        
        let request = try await makeRequest(
            method: "PUT",
            path: "/api/v1/profile",
            body: body
        )
        
        let response = try await execute(request, responseType: UserProfileResponse.self)
        return response.profile
    }
    
    func deleteUserProfile() async throws {
        let request = try await makeRequest(
            method: "DELETE",
            path: "/api/v1/profile"
        )
        
        _ = try await execute(request, responseType: EmptyResponse.self)
    }
    
    // MARK: - Chats
    
    func getChats(bookId: String) async throws -> [BookChat] {
        let request = try await makeRequest(
            method: "GET",
            path: "/api/v1/books/\(bookId)/chats"
        )
        
        let response = try await execute(request, responseType: ChatsResponse.self)
        return response.chats.map { $0.toDomain(bookId: bookId) }
    }
    
    func createChat(bookId: String, message: String, messageType: MessageType) async throws -> BookChat {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        
        let body = try encoder.encode([
            "message": message,
            "messageType": messageType.rawValue
        ])
        
        let request = try await makeRequest(
            method: "POST",
            path: "/api/v1/books/\(bookId)/chats",
            body: body
        )
        
        let response = try await execute(request, responseType: ChatResponse.self)
        return response.chat.toDomain(bookId: bookId)
    }
    
    func updateChat(bookId: String, chatId: String, message: String) async throws -> BookChat {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        encoder.dateEncodingStrategy = .formatted(formatter)
        
        let body = try encoder.encode([
            "message": message
        ])
        
        let request = try await makeRequest(
            method: "PUT",
            path: "/api/v1/books/\(bookId)/chats/\(chatId)",
            body: body
        )
        
        let response = try await execute(request, responseType: ChatResponse.self)
        return response.chat.toDomain(bookId: bookId)
    }
    
    func deleteChat(bookId: String, chatId: String) async throws {
        let request = try await makeRequest(
            method: "DELETE",
            path: "/api/v1/books/\(bookId)/chats/\(chatId)"
        )
        
        _ = try await execute(request, responseType: EmptyResponse.self)
    }
    
    // MARK: - Upload
    
    func uploadProfileImage(imageData: Data) async throws -> String {
        var request = try await makeRequest(
            method: "POST",
            path: "/api/v1/upload/profile-image"
        )
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let response = try await execute(request, responseType: UploadResponse.self)
        return response.url
    }
    
    func uploadBookCover(bookId: String, imageData: Data) async throws -> String {
        var request = try await makeRequest(
            method: "POST",
            path: "/api/v1/upload/books/\(bookId)/cover"
        )
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"cover.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let response = try await execute(request, responseType: UploadResponse.self)
        return response.url
    }
    
    func uploadChatPhoto(bookId: String, imageData: Data) async throws -> String {
        var request = try await makeRequest(
            method: "POST",
            path: "/api/v1/upload/books/\(bookId)/chat-photo"
        )
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let response = try await execute(request, responseType: UploadResponse.self)
        return response.url
    }
    
    func deleteImage(url: String) async throws {
        let encoder = JSONEncoder()
        let body = try encoder.encode(["url": url])
        
        let request = try await makeRequest(
            method: "DELETE",
            path: "/api/v1/upload/images",
            body: body
        )
        
        _ = try await execute(request, responseType: EmptyResponse.self)
    }
}

// MARK: - Response Types

struct ErrorResponse: Decodable {
    let error: ErrorDetail
    
    struct ErrorDetail: Decodable {
        let code: String
        let message: String
    }
}

struct AIResponseResult: Decodable {
    let success: Bool
    let chatId: String
    let message: String
}

struct SummaryResult: Decodable {
    let success: Bool
    let summary: String
}

struct BookSearchResult: Decodable {
    let books: [APIBookDTO]
}

struct PublicBooksResult: Decodable {
    let books: [APIBookDTO]
}

struct DeleteAccountResult: Decodable {
    let success: Bool
    let deletedCollections: [String]
    let errors: [String]
}

// MARK: - CRUD Response Types

struct EmptyResponse: Decodable {}

struct BooksResponse: Decodable {
    let books: [BookDTO]
}

struct BookResponse: Decodable {
    let book: BookDTO
}

struct ActivitiesResponse: Decodable {
    let activities: [ActivityDTO]
}

struct ActivityResponse: Decodable {
    let activity: ActivityDTO
}

struct GoalsResponse: Decodable {
    let goals: [GoalDTO]
}

struct GoalResponse: Decodable {
    let goal: GoalDTO
}

struct AchievementsResponse: Decodable {
    let achievements: [AchievementDTO]
}

struct AchievementResponse: Decodable {
    let achievement: AchievementDTO
}

struct StreaksResponse: Decodable {
    let streaks: [StreakDTO]
}

struct StreakResponse: Decodable {
    let streak: StreakDTO
}

struct UserProfileResponse: Decodable {
    let profile: UserProfile
}

struct ChatsResponse: Decodable {
    let chats: [ChatDTO]
}

struct ChatResponse: Decodable {
    let chat: ChatDTO
}

struct UploadResponse: Decodable {
    let success: Bool
    let url: String
}

// MARK: - Request Types

struct BookCreateRequest: Encodable {
    let isbn: String?
    let title: String
    let author: String
    let publisher: String?
    let publishedDate: Date?
    let pageCount: Int?
    let description: String?
    let coverImageUrl: String?
    let dataSource: String
    let status: String
    let rating: Double?
    let readingProgress: Double?
    let currentPage: Int?
    let startDate: Date?
    let completedDate: Date?
    let priority: Int?
    let plannedReadingDate: Date?
    let reminderEnabled: Bool
    let purchaseLinks: [PurchaseLink]?
    let memo: String?
    let tags: [String]
    
    init(from book: Book) {
        self.isbn = book.isbn
        self.title = book.title
        self.author = book.author
        self.publisher = book.publisher
        self.publishedDate = book.publishedDate
        self.pageCount = book.pageCount
        self.description = book.description
        self.coverImageUrl = book.coverImageUrl
        self.dataSource = book.dataSource.rawValue
        self.status = book.status.rawValue
        self.rating = book.rating
        self.readingProgress = book.readingProgress
        self.currentPage = book.currentPage
        self.startDate = book.startDate
        self.completedDate = book.completedDate
        self.priority = book.priority
        self.plannedReadingDate = book.plannedReadingDate
        self.reminderEnabled = book.reminderEnabled
        self.purchaseLinks = book.purchaseLinks
        self.memo = book.memo
        self.tags = book.tags
    }
}

struct BookUpdateRequest: Encodable {
    let status: String?
    let rating: Double?
    let readingProgress: Double?
    let currentPage: Int?
    let startDate: Date?
    let completedDate: Date?
    let priority: Int?
    let plannedReadingDate: Date?
    let reminderEnabled: Bool?
    let purchaseLinks: [PurchaseLink]?
    let memo: String?
    let tags: [String]?
    let aiSummary: String?
    let summaryGeneratedAt: Date?
    
    init(from book: Book) {
        self.status = book.status.rawValue
        self.rating = book.rating
        self.readingProgress = book.readingProgress
        self.currentPage = book.currentPage
        self.startDate = book.startDate
        self.completedDate = book.completedDate
        self.priority = book.priority
        self.plannedReadingDate = book.plannedReadingDate
        self.reminderEnabled = book.reminderEnabled
        self.purchaseLinks = book.purchaseLinks
        self.memo = book.memo
        self.tags = book.tags
        self.aiSummary = book.aiSummary
        self.summaryGeneratedAt = book.summaryGeneratedAt
    }
}