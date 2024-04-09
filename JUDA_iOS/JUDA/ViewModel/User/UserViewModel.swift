//
//  UserViewModel.swift
//  JUDA
//
//  Created by phang on 3/7/24.
//

import SwiftUI
import FirebaseCore

// MARK: - User ( 타 유저 데이터 받기 )
@MainActor
final class UserViewModel: ObservableObject {
    // 유저
    @Published var user: User?
    // 로딩 중
    @Published var isLoading: Bool = false
    // Firebase User Service
    private let firebaseUserService = FirebaseUserService()
    
    private enum UserResult {
        case userField(UserField?)
        case posts([Post]?)
        case likedPosts([Post]?)
        case likedDrinks([Drink]?)
        case notifications([UserNotification]?)
    }
    
    // 유저 데이터 받아오기 ( 본인 X / 타 유저 )
    func getUser(uid: String) async {
        isLoading = true
        var userFieldResult: UserField?
        var postsResult: [Post]?
        var likedPostsResult: [Post]?
        var likedDrinksResult: [Drink]?
        var notificationsResult: [UserNotification]?

        await withTaskGroup(of: UserResult.self) { taskGroup in
            // UserField 받아오기
            taskGroup.addTask { .userField(await self.getUserField(uid: uid)) }
            // Posts 받아오기
            taskGroup.addTask { .posts(await self.getUserPosts(uid: uid)) }
            // LikedPosts 받아오기
            taskGroup.addTask { .likedPosts(await self.getUserLikedPosts(uid: uid)) }
            // LikedDrinks 받아오기
            taskGroup.addTask { .likedDrinks(await self.getUserLikedDrinks(uid: uid)) }
            // Notifications 받아오기
            taskGroup.addTask { .notifications(await self.getUserNotifications(uid: uid)) }
            
            for await result in taskGroup {
                switch result {
                case .userField(let userField):
                    userFieldResult = userField
                case .posts(let posts):
                    postsResult = posts
                case .likedPosts(let likedPosts):
                    likedPostsResult = likedPosts
                case .likedDrinks(let likedDrinks):
                    likedDrinksResult = likedDrinks
                case .notifications(let notifications):
                    notificationsResult = notifications
                }
            }
        }
        
        guard let userField = userFieldResult,
              let posts = postsResult,
              let likedPosts = likedPostsResult,
              let likedDrinks = likedDrinksResult,
              let notifications = notificationsResult else { return }
        
        user = User(userField: userField,
                    posts: posts,
                    likedPosts: likedPosts,
                    likedDrinks: likedDrinks,
                    notifications: notifications)
        
        isLoading = false
    }
    
    // UserField 받아오기
    private func getUserField(uid: String) async -> UserField? {
        do {
            let userField = try await firebaseUserService.fetchUserFieldData(uid: uid, userType: .otherUser)
            return userField
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    // Posts 받아오기
    private func getUserPosts(uid: String) async -> [Post]? {
        do {
            let posts = try await firebaseUserService.fetchUserWrittenPosts(uid: uid)
            return posts
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    // LikedPosts 받아오기
    private func getUserLikedPosts(uid: String) async -> [Post]? {
        do {
            let likedPosts = try await firebaseUserService.fetchUserLikedPosts(uid: uid)
            return likedPosts
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    // LikedDrinks 받아오기
    private func getUserLikedDrinks(uid: String) async -> [Drink]? {
        do {
            let likedDrinks = try await firebaseUserService.fetchUserLikedDrink(uid: uid)
            return likedDrinks
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    // Notifications 받아오기
    private func getUserNotifications(uid: String) async -> [UserNotification]? {
        do {
            let notifications = try await firebaseUserService.fetchUserNotifications(uid: uid)
            return notifications
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
