import Foundation

final class UserProfileRepository {
    static let shared = UserProfileRepository()
    
    private let apiClient = APIClient.shared
    
    private init() {}
    
    func getUserProfile() async throws -> UserProfile? {
        return try await apiClient.getUserProfile()
    }
    
    func createUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        return try await apiClient.createUserProfile(profile)
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        _ = try await apiClient.updateUserProfile(profile)
    }
    
    func deleteUserProfile() async throws {
        try await apiClient.deleteUserProfile()
    }
    
    func createInitialProfile(for user: User) async throws -> UserProfile {
        let profile = UserProfile(
            id: user.id,
            displayName: user.displayName.isEmpty ? user.email : user.displayName,
            avatarImageId: nil,  // 初期プロフィールでは画像なし
            bio: nil,
            favoriteGenres: [],
            readingGoal: nil,
            isPublic: false
        )
        
        return try await createUserProfile(profile)
    }
}