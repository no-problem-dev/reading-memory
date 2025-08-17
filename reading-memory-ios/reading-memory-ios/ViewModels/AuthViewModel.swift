import Foundation
import SwiftUI

@Observable
final class AuthViewModel {
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?
    
    init() {
        // TODO: Initialize auth state observation
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement Google Sign In
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement Sign Out
        
        isLoading = false
    }
}