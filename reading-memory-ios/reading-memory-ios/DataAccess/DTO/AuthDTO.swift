import Foundation

// MARK: - Initialize User
struct InitializeUserResult: Codable {
    let initialized: Bool
    let hasProfile: Bool
    let message: String
}

// MARK: - Onboarding Status
struct OnboardingStatus: Codable {
    let needsOnboarding: Bool
    let hasProfile: Bool
    let hasGoals: Bool
}

// MARK: - Onboarding Result
struct OnboardingResult: Codable {
    let success: Bool
    let message: String
}