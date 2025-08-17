import Foundation

struct User: Identifiable {
    let id: String
    let email: String
    let provider: AuthProvider
    let createdAt: Date
    let lastLoginAt: Date
    
    enum AuthProvider {
        case google
        case apple
    }
}