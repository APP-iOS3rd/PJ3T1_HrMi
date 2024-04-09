//
//  PostTopView.swift
//  JUDA
//
//  Created by 백대홍 on 2/26/24.
//

import SwiftUI

struct PostTopView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var mainViewModel: MainViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text("인기 술상")
                    .font(.semibold20)
                
                Spacer()
                
                Button {
					appViewModel.selectedTabIndex = 2
                } label: {
                    Text("더보기")
                        .foregroundStyle(.gray01)
                        .font(.semibold16)
                }
            }
            .padding(20)

            ForEach(mainViewModel.posts, id: \.postField.postID) { post in
                if authViewModel.signInStatus {
                    NavigationLink(value: Route
                        .PostDetail(postUserType: authViewModel.currentUser?.userField.userID == post.postField.user.userID ? .writer : .reader,
                                    post: post,
                                    usedTo: .main)) {
                        if let user = authViewModel.currentUser {
                            PostListCell(post: post,
                                         isLiked: post.likedUsersID.contains(user.userField.userID ?? ""))
                        } else {
                            PostListCell(post: post,
                                         isLiked: false)
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
        }
    }
}
