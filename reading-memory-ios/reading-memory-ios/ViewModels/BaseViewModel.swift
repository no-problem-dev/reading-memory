import Foundation
import SwiftUI

@MainActor
@Observable
class BaseViewModel {
    var isLoading = false
    var errorMessage: String?
    var showError = false
    
    // データ読み込み管理
    private(set) var hasLoadedInitialData = false
    private var loadTask: Task<Void, Never>?
    private var lastDataFetch: Date?
    
    // キャッシュ有効期限（デフォルト5分）
    var cacheValidityDuration: TimeInterval = 300
    
    deinit {
        // Note: deinit内でのタスクキャンセルは、タスクがTaskストアで
        // 自動的に管理されるため実際には不要
    }
    
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
            print("DEBUG: Error in withLoadingNoThrow: \(error)")
            print("DEBUG: Error localized: \(error.localizedDescription)")
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
    
    // キャッシュ管理
    func shouldRefreshData() -> Bool {
        guard hasLoadedInitialData else { return true }
        
        if let lastFetch = lastDataFetch {
            return Date().timeIntervalSince(lastFetch) > cacheValidityDuration
        }
        
        return true
    }
    
    func markDataAsFetched() {
        hasLoadedInitialData = true
        lastDataFetch = Date()
    }
    
    // タスク管理
    func cancelCurrentTask() {
        loadTask?.cancel()
    }
    
    func executeLoadTask(_ action: @escaping () async -> Void) async {
        cancelCurrentTask()
        
        loadTask = Task {
            guard !Task.isCancelled else { return }
            await action()
        }
        
        await loadTask?.value
    }
    
    // 強制リフレッシュ
    func forceRefresh() {
        hasLoadedInitialData = false
        lastDataFetch = nil
    }
}