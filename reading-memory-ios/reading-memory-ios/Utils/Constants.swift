//
//  Constants.swift
//  reading-memory-ios
//
//  Created by Claude on 2025/08/17.
//

import Foundation

enum Constants {
    enum Collection {
        static let users = "users"
        static let userProfiles = "userProfiles"
        static let books = "books"
        static let userBooks = "userBooks"
        static let chats = "chats"
    }
    
    enum UserDefaults {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let currentUserId = "currentUserId"
    }
    
    enum UI {
        static let maxBooksPerMonth = 10
        static let maxChatMessageLength = 1000
        static let imageCompressionQuality = 0.8
    }
}