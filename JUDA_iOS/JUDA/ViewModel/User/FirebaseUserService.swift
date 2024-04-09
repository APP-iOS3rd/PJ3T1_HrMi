//
//  FirebaseUserService.swift
//  JUDA
//
//  Created by phang on 3/6/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

// MARK: - Firebase : User
@MainActor
final class FirebaseUserService {
    // Firestore - db 연결
    private let db = Firestore.firestore()
    private let userCollection = "users"
    private let postCollection = "posts"
    private let likedPostCollection = "likedPosts"
    private let likedDrinkCollection = "likedDrinks"
    private let notificationCollection = "notifications"
    // Firebase Post Service
    private let firestorePostService = FirestorePostService()
    // Firebase Drink Service
    private let firestoreDrinkService = FirestoreDrinkService()
    
    
    // firestore 에서 UserField 정보 가져오기
    func fetchUserFieldData(uid: String, userType: UserType = .user) async throws -> UserField {
        do {
            var document: DocumentSnapshot
            switch userType {
            case .user:
                document = try await db.collection(userCollection).document(uid).getDocument(source: .cache)
            case .otherUser:
                document = try await db.collection(userCollection).document(uid).getDocument(source: .server)
            }
            let userData = try document.data(as: UserField.self)
            print("fetchUserFieldData from cache")
            return userData
        } catch {
            throw FetchUserError.userField
        }
    }
    
    // 해당 유저가 작성한 post 리스트 받아오기
    func fetchUserWrittenPosts(uid: String) async throws -> [Post] {
        let userWrittenPostRef = db.collection(userCollection).document(uid).collection(postCollection)
        // Post 가져오는 코드 - FirestorePostService
        let userWrittenPostList = try await firestorePostService.fetchPostCollection(collection: userWrittenPostRef)
        return userWrittenPostList
    }
    
    // 해당 유저가 좋아요 누른 post 리스트 받아오기
    func fetchUserLikedPosts(uid: String) async throws -> [Post] {
        let userLikedPostRef = db.collection(userCollection).document(uid).collection(likedPostCollection)
        // Post 가져오는 코드 - FirestorePostService
        let userLikedPostList = try await firestorePostService.fetchPostCollection(collection: userLikedPostRef)
        return userLikedPostList
    }
    
    // 해당 유저가 좋아요 누른 drink 리스트 받아오기
    func fetchUserLikedDrink(uid: String) async throws -> [Drink] {
        let userLikedDrinkRef = db.collection(userCollection).document(uid).collection(likedDrinkCollection)
        // Drink 가져오는 코드 - FirestoreDrinkService
        let userLikedPostList = try await firestoreDrinkService.fetchDrinkCollection(collection: userLikedDrinkRef)
        return userLikedPostList
    }
    
    // 해당 유저의 notification 리스트 받아오기
    func fetchUserNotifications(uid: String) async throws -> [UserNotification] {
        do {
            var result = [UserNotification]()
            let userNotificationRef = db.collection(userCollection).document(uid).collection(notificationCollection)
            let userNotificationSnapshot = try await userNotificationRef.getDocuments()
            for notificationDocument in userNotificationSnapshot.documents {
                let notificationFieldData = try notificationDocument.data(as: NotificationField.self)
                let notificationID = notificationDocument.documentID
                let notificationPostRef = userNotificationRef.document(notificationID).collection("likedPost")
                // notification 해당되는 post 가져오는 코드 - FirestorePostService
                let notificationPostList = try await firestorePostService.fetchPostCollection(collection: notificationPostRef)
                // post는 원래 리스트가 아니라 1개. 하지만, postID 가 필요해서 리스트로 받은 뒤 first 추출
                guard let notificationPostData = notificationPostList.first else {
                    throw PostError.documentFetch
                }
                result.append(UserNotification(notificationField: notificationFieldData,
                                               likedPost: notificationPostData))
            }
            return result
        } catch let error {
            throw error
        }
    }
}
