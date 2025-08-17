import Foundation

struct User: Identifiable, Equatable {
    let id: String
    let email: String
    let displayName: String
    let photoURL: String?
    let provider: AuthProvider
    let createdAt: Date
    let lastLoginAt: Date
    
    enum AuthProvider: String {
        case google = "google.com"
        case apple = "apple.com"
        case email = "password"
        
        init(providerId: String) {
            switch providerId {
            case "google.com":
                self = .google
            case "apple.com":
                self = .apple
            default:
                self = .email
            }
        }
    }
}