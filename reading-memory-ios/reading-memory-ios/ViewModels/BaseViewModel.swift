import Foundation
import SwiftUI

@MainActor
@Observable
class BaseViewModel {
    var isLoading = false
    var errorMessage: String?
    var showError = false
    
    func withLoading<T>(_ action: @escaping () async throws -> T) async throws -> T {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await action()
        } catch {
            handleError(error)
            throw error
        }
    }
    
    func withLoadingNoThrow(_ action: @escaping () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await action()
        } catch {
            handleError(error)
        }
    }
    
    func handleError(_ error: Error) {
        let appError = AppError.from(error)
        errorMessage = appError.errorDescription
        showError = true
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
}