//
//  User.swift
//  JUDA
//
//  Created by phang on 2/15/24.
//

import Foundation
import FirebaseFirestore

// MARK: - User
// Firebase users 컬렉션 데이터 모델
struct User {
    var userField: UserField
    var posts: [Post]
    var likedPosts: [Post]
    var likedDrinks: [Drink]
    var notifications: [UserNotification]
}

// Firebase users 컬렉션 필드 데이터 모델
struct UserField: Codable {
	@DocumentID var userID: String?
    var name: String
    var age: Int
    var gender: String
	var fcmToken: String
    var notificationAllowed: Bool
    var profileImageURL: URL?
    var authProviders: String // AuthProviderOption - rawValue
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.userField.userID == rhs.userField.userID
    }
}

// MARK: - UserNotification
struct UserNotification: Equatable {
    @DocumentID var userNotificationID: String?
    var notificationField: NotificationField
    var likedPost: Post
    
    static func == (lhs: UserNotification, rhs: UserNotification) -> Bool {
        lhs.userNotificationID == rhs.userNotificationID
    }
}

// Firebase users/notificationList 컬렉션 데이터 모델
struct NotificationField: Codable {
    var likedUser: NotificationLikedUser
    var isChecked: Bool
    var likedTime: Date
    var thumbnailImageURL: URL?
}

struct NotificationLikedUser: Codable {
    var userID: String
    var userName: String
}
