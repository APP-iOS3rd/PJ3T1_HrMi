//
//  PostCell.swift
//  JUDA
//
//  Created by Minjae Kim on 1/25/24.
//

import SwiftUI
import Kingfisher

// MARK: - 술상 그리드 셀
struct PostCell: View {
	@EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var postViewModel: PostViewModel
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var userViewModel: UserViewModel

	@State private var isLike: Bool = false
	@State private var likeCount: Int = 0
	
	let usedTo: WhereUsedPostGridContent
	let post: Post
	private let debouncer = Debouncer(delay: 0.5)
    
	var body: some View {
		// VStack에 기본적인 spacing이 들어가기 때문에 0으로 설정
		VStack(spacing: 0) {
			ZStack(alignment: .topTrailing) {
				// 게시글 사진리스트의 첫 번째 사진
                KFImage.url(post.postField.imagesURL.first)
                    .placeholder {
                        CircularLoaderView(size: 20)
                            .frame(width: 170, height: 170)
                            .clipped()
                    }
                    .loadDiskFileSynchronously(true) // 디스크에서 동기적으로 이미지 가져오기
                    .cancelOnDisappear(true) // 화면 이동 시, 진행중인 다운로드 중단
                    .cacheMemoryOnly() // 메모리 캐시만 사용 (디스크 X)
                    .fade(duration: 0.2) // 이미지 부드럽게 띄우기
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 170, height: 170)
                    .clipped()
				// 게시글 사진이 2장 이상일 경우, 상자 아이콘이 사진의 trailing 상단에 보여짐
				if post.postField.imagesURL.count >= 2 {
					Image(systemName: "square.on.square.fill")
						.frame(width: 18, height: 18)
						.foregroundStyle(.white)
						.padding([.top, .trailing], 10)
				}
			}
			HStack {
                HStack {
                    // 사용자의 프로필 사진
                    if let url = post.postField.user.userProfileImageURL {
                        PostCellUserProfileKFImage(url: url)
                    } else {
						Image("defaultprofileimage")
							.resizable()
							.frame(width: 20, height: 20)
							.clipShape(.circle)
					}
					// 사용자의 닉네임
                    Text(post.postField.user.userName)
						.lineLimit(1)
						.font(.regular14)
						.foregroundStyle(.mainBlack)
				}
				.padding(.leading, 5)
				
				Spacer()
				
				// 좋아요 버튼
				HStack {
					// 좋아요를 등록 -> 빨간색이 채워진 하트
					// 좋아요를 해제 -> 테두리가 회색인 하트
					Button {
                        if authViewModel.signInStatus {
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
                        } else {
                            authViewModel.isShowLoginDialog = true
                        }
					} label: {
						Image(systemName: isLike ? "heart.fill" : "heart")
							.foregroundStyle(isLike ? .mainAccent01 : .gray01)
					}
					Text(Formatter.formattedPostLikesCount(likeCount))
						.foregroundStyle(.gray01)
				}
				.font(.regular14)
				.padding(.trailing, 5)
			}
			.frame(height: 35)
		}
		.frame(maxWidth: 170)
		.task {
            if authViewModel.signInStatus,
               let user = authViewModel.currentUser {
                self.isLike = user.likedPosts.contains { $0 == post }
			}
            self.likeCount = post.postField.likedCount
		}
	}
}

// MARK: - PostCell 의 이미지 프로필에서 사용하는 KFImage
struct PostCellUserProfileKFImage: View {
    let url: URL
    
    var body: some View {
        KFImage.url(url)
            .loadDiskFileSynchronously(true) // 디스크에서 동기적으로 이미지 가져오기
            .cancelOnDisappear(true) // 화면 이동 시, 진행중인 다운로드 중단
            .cacheMemoryOnly() // 메모리 캐시만 사용 (디스크 X)
            .fade(duration: 0.2) // 이미지 부드럽게 띄우기
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 20, height: 20)
            .clipShape(.circle)
    }
}
