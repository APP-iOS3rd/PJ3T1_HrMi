//
//  PostInfo.swift
//  JUDA
//
//  Created by Minjae Kim on 1/29/24.
//

import SwiftUI
import Kingfisher

// MARK: - 술상 디테일에서 상단에 유저 + 글 작성 시간 + 좋아요
struct PostInfo: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
	@EnvironmentObject private var authViewModel: AuthViewModel
	@EnvironmentObject private var postViewModel: PostViewModel
    @EnvironmentObject private var mainViewModel: MainViewModel
    
	@State private var isLike: Bool = false
	@State private var likeCount: Int = 0
	let post: Post
    let usedTo: WhereUsedPostGridContent
    
	private let debouncer = Debouncer(delay: 0.5)
    
    var body: some View {
        HStack {
            // 사용자의 프로필
            HStack(alignment: .center, spacing: 10) {
                // 이미지
                if let url = post.postField.user.userProfileImageURL {
                    PostInfoUserProfileKFImage(url: url)
                } else {
                    Image("defaultprofileimage")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .clipShape(.circle)
                }
                VStack(alignment: .leading) {
                    NavigationLink(value: Route
                        .NavigationProfile(userID: post.postField.user.userID,
                                           usedTo: usedTo)) {
                        // 사용자의 닉네임
                        Text(post.postField.user.userName)
                            .lineLimit(1)
                            .font(.regular18)
                            .foregroundStyle(.mainBlack)
                    }
                    // 게시글 올린 날짜
                    let dateString = Formatter.dateToString(date: post.postField.postedTime)
                    Text(dateString)
                        .font(.regular14)
                        .foregroundStyle(.gray01)
                }
            }
            //
            Spacer()
            // 좋아요 버튼
            HStack(spacing: 4) {
                // 좋아요를 등록 -> 빨간색이 채워진 하트
                // 좋아요를 해제 -> 테두리가 회색인 하트
                Button {
                    isLike.toggle()
                    debouncer.call {
                        if isLike {
                            likeCount += 1
                        } else {
                            likeCount -= 1
                        }
                        Task {
                            await authViewModel.updateLikedPosts(isLiked: isLike, selectedPost: post)
                        }
                    }
                } label: {
                    Image(systemName: isLike ? "heart.fill" : "heart")
                        .foregroundStyle(isLike ? .mainAccent01 : .gray01)
                }
                // 좋아요 수
                Text(Formatter.formattedPostLikesCount(likeCount))
                    .foregroundStyle(.gray01)
            }
            .font(.regular16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .task {
            if authViewModel.signInStatus,
               let user = authViewModel.currentUser {
                self.isLike = user.likedPosts.contains { $0 == post }
            }
            self.likeCount = post.postField.likedCount
        }
    }
}

// MARK: - PostInfo 의 이미지 프로필에서 사용하는 KFImage
struct PostInfoUserProfileKFImage: View {
    let url: URL
    
    var body: some View {
        KFImage.url(url)
            .loadDiskFileSynchronously(true) // 디스크에서 동기적으로 이미지 가져오기
            .cancelOnDisappear(true) // 화면 이동 시, 진행중인 다운로드 중단
            .cacheMemoryOnly() // 메모리 캐시만 사용 (디스크 X)
            .fade(duration: 0.2) // 이미지 부드럽게 띄우기
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 30, height: 30)
            .clipShape(.circle)
    }
}
