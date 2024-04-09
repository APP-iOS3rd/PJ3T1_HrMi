//
//  TaggedTrendingPosts.swift
//  JUDA
//
//  Created by phang on 1/30/24.
//

import SwiftUI

// MARK: - 태그된 인기 술상
struct TaggedTrendingPosts: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel

    @State private var posts: [Post] = []
    @State private var isLoading: Bool = true
    let drink: Drink

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("태그된 인기 술상")
                .font(.semibold18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            VStack(spacing: 0) {
                ForEach(posts, id: \.postField.postID) { post in
                    if !isLoading {
                        if authViewModel.signInStatus {
                            NavigationLink(value: Route
                                .PostDetail(postUserType: post.postField.user.userID == authViewModel.currentUser?.userField.userID ? .writer : .reader,
                                            post: post,
                                            usedTo: .drinkDetail)) {
                                if !isLoading {
                                    if let user = authViewModel.currentUser {
                                        PostListCell(post: post,
                                                     isLiked: user.likedPosts.contains(post))
                                    } else {
                                        PostListCell(post: post,
                                                     isLiked: false)
                                    }
                                }
                            }
                        } else {
                            PostListCell(post: post, 
                                         isLiked: false)
                                .onTapGesture {
                                    authViewModel.isShowLoginDialog = true
                                }
                        }
                    }
                    else {
                       ShimmerPostListCell()
                   }
                }
            }
        }
        .padding(.vertical, 10)
        .task {
            // 태그된 인기 게시물 가져오기
            self.isLoading = true
            if posts.isEmpty {
                self.posts = drinkViewModel.getTopTrendingPosts(drink: drink)
            }
            self.isLoading = false
        }
    }
}
