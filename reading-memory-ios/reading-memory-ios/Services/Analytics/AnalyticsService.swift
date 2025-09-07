import SwiftUI
import FirebaseAnalytics
import FirebaseAuth

@MainActor
@Observable
final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private init() {
        // Firebase Analyticsの初期設定
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // SwiftUIでは自動screen_view収集が機能しないため、
        // 手動で管理することを明示
        #if DEBUG
        print("📊 Analytics: Manual screen tracking enabled for SwiftUI")
        print("📊 Analytics: DebugView should be available at https://console.firebase.google.com/project/_/analytics/debugview")
        #endif
    }
    
    // MARK: - User Management
    
    /// ユーザーIDの設定（ログイン時に呼び出し）
    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
    }
    
    /// ユーザープロパティの設定
    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    /// ユーザープロパティの一括設定
    func updateUserProperties(isPremium: Bool, bookCount: Int) {
        setUserProperty(isPremium ? "premium" : "free", forName: "user_type")
        setUserProperty("\(bookCount)", forName: "book_count")
    }
    
    // MARK: - Event Tracking
    
    /// イベントのトラッキング
    func track(_ event: AnalyticsEvent) {
        switch event {
        case .screenView(let screen):
            trackScreenView(screen)
        case .userAction(let action):
            trackUserAction(action)
        case .bookEvent(let bookEvent):
            trackBookEvent(bookEvent)
        case .error(let type, let message):
            trackError(type: type, message: message)
        }
    }
    
    // MARK: - Private Methods
    
    private func trackScreenView(_ screen: ScreenName) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screen.rawValue,
            AnalyticsParameterScreenClass: "\(screen.rawValue)_view"
        ])
    }
    
    private func trackUserAction(_ action: UserAction) {
        switch action {
        case .login(let method):
            Analytics.logEvent(AnalyticsEventLogin, parameters: [
                AnalyticsParameterMethod: method
            ])
        case .logout:
            Analytics.logEvent("logout", parameters: nil)
        case .search(let query, let resultCount):
            Analytics.logEvent(AnalyticsEventSearch, parameters: [
                AnalyticsParameterSearchTerm: query,
                "result_count": resultCount
            ])
        case .filterApplied(let filterType):
            Analytics.logEvent("filter_applied", parameters: [
                "filter_type": filterType
            ])
        case .sortChanged(let sortType):
            Analytics.logEvent("sort_changed", parameters: [
                "sort_type": sortType
            ])
        case .tabSelected(let tabName):
            Analytics.logEvent("tab_selected", parameters: [
                "tab_name": tabName
            ])
        case .sectionTapped(let section):
            Analytics.logEvent("section_tapped", parameters: [
                "section": section
            ])
        case .barcodeScan(let success, let isbn):
            var params: [String: Any] = ["success": success]
            if let isbn = isbn {
                params["isbn"] = isbn
            }
            Analytics.logEvent("barcode_scan", parameters: params)
        }
    }
    
    private func trackBookEvent(_ event: BookEvent) {
        switch event {
        case .added(let bookId, let method, let source):
            Analytics.logEvent("book_added", parameters: [
                "book_id": bookId,
                "method": method,
                "source": source
            ])
        case .statusChanged(let bookId, let from, let to):
            Analytics.logEvent("book_status_changed", parameters: [
                "book_id": bookId,
                "from_status": from,
                "to_status": to
            ])
        case .ratingChanged(let bookId, let rating):
            Analytics.logEvent("book_rating_changed", parameters: [
                "book_id": bookId,
                "rating": rating
            ])
        case .chatMessageSent(let bookId, let messageLength):
            Analytics.logEvent("chat_message_sent", parameters: [
                "book_id": bookId,
                "message_length": messageLength
            ])
        case .summaryGenerated(let bookId):
            Analytics.logEvent("summary_generated", parameters: [
                "book_id": bookId
            ])
        case .bookDeleted(let bookId):
            Analytics.logEvent("book_deleted", parameters: [
                "book_id": bookId
            ])
        case .bookSelected(let bookId, let fromScreen):
            Analytics.logEvent("book_selected", parameters: [
                "book_id": bookId,
                "from_screen": fromScreen
            ])
        case .priorityChanged(let bookId, let priority):
            Analytics.logEvent("priority_changed", parameters: [
                "book_id": bookId,
                "priority": priority
            ])
        case .reminderSet(let bookId, let reminderDate):
            Analytics.logEvent("reminder_set", parameters: [
                "book_id": bookId,
                "reminder_date": reminderDate
            ])
        }
    }
    
    private func trackError(type: ErrorType, message: String) {
        Analytics.logEvent("app_error", parameters: [
            "error_type": type.rawValue,
            "error_message": message
        ])
    }
}

// MARK: - View Extension for Screen Tracking

extension View {
    /// SwiftUIビューのスクリーントラッキングを簡単にするモディファイア
    func trackScreen(_ screen: ScreenName) -> some View {
        self.onAppear {
            AnalyticsService.shared.track(.screenView(screen: screen))
        }
    }
}