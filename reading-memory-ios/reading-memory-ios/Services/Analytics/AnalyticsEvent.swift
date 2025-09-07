import Foundation

// MARK: - Analytics Events
enum AnalyticsEvent {
    case screenView(screen: ScreenName)
    case userAction(action: UserAction)
    case bookEvent(event: BookEvent)
    case error(type: ErrorType, message: String)
}

// MARK: - Screen Names
enum ScreenName: String {
    case bookShelf = "book_shelf"
    case bookDetail = "book_detail"
    case bookChat = "book_chat"
    case discovery = "discovery"
    case searchBooks = "search_books"
    case wantToReadList = "want_to_read_list"
    case profile = "profile"
    case editProfile = "edit_profile"
    case settings = "settings"
    case subscription = "subscription"
}

// MARK: - User Actions
enum UserAction {
    case login(method: String)
    case logout
    case search(query: String, resultCount: Int)
    case filterApplied(filterType: String)
    case sortChanged(sortType: String)
    case tabSelected(tabName: String)
    case sectionTapped(section: String)
    case barcodeScan(success: Bool, isbn: String?)
}

// MARK: - Book Events
enum BookEvent {
    case added(bookId: String, method: String, source: String)
    case statusChanged(bookId: String, from: String, to: String)
    case ratingChanged(bookId: String, rating: Double)
    case chatMessageSent(bookId: String, messageLength: Int)
    case summaryGenerated(bookId: String)
    case bookDeleted(bookId: String)
    case bookSelected(bookId: String, fromScreen: String)
    case priorityChanged(bookId: String, priority: String)
    case reminderSet(bookId: String, reminderDate: String)
}

// MARK: - Error Types
enum ErrorType: String {
    case network = "network_error"
    case authentication = "auth_error"
    case dataFetch = "data_fetch_error"
    case unknown = "unknown_error"
}