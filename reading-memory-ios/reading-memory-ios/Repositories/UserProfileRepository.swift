import Foundation
import FirebaseFirestore
import FirebaseAuth

final class UserProfileRepository: BaseRepository {
    typealias T = UserProfile
    let collectionName = "userProfiles"
    
    static let shared = UserProfileRepository()
    
    private init() {}
    
    func getUserProfile(userId: String) async throws -> UserProfile? {
        let document = try await db.collection(collectionName).document(userId).getDocument()
        return try documentToModel(document)
    }
    
    func createUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        let data = try modelToData(profile)
        try await db.collection(collectionName).document(profile.id).setData(data)
        return profile
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        var updatedProfile = UserProfile(
            id: profile.id,
            displayName: profile.displayName,
            profileImageUrl: profile.profileImageUrl,
            bio: profile.bio,
            favoriteGenres: profile.favoriteGenres,
            readingGoal: profile.readingGoal,
            isPublic: profile.isPublic,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
        
        let data = try modelToData(updatedProfile)
        try await db.collection(collectionName).document(profile.id).setData(data, merge: true)
    }
    
    func deleteUserProfile(userId: String) async throws {
        try await db.collection(collectionName).document(userId).delete()
    }
    
    func createInitialProfile(for user: User) async throws -> UserProfile {
        let profile = UserProfile(
            id: user.id,
            displayName: user.displayName.isEmpty ? user.email : user.displayName,
            profileImageUrl: user.photoURL,
            bio: nil,
            favoriteGenres: [],
            readingGoal: nil,
            isPublic: false
        )
        
        return try await createUserProfile(profile)
    }
}