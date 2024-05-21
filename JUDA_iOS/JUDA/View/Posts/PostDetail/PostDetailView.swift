//
//  PostDetailView.swift
//  JUDA
//
//  Created by Minjae Kim on 1/29/24.
//

import SwiftUI

// MARK: - 술상 디테일 화면
struct PostDetailView: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var postViewModel: PostViewModel
    @EnvironmentObject private var recordViewModel: RecordViewModel
	
    @State private var shareImage: Image = Image("AppIcon") // shareLink 용 이미지

	let postUserType: PostUserType
	let post: Post
	let usedTo: WhereUsedPostGridContent

	@State private var isReportPresented = false
	@State private var isDeleteDialogPresented = false
    
	var body: some View {
        ZStack {
            // 사용자, 글 정보 + 이미지 + 술 태그 + 글 내용 + 음식 태그
            // MARK: iOS 16.4 이상
            if #available(iOS 16.4, *) {
                ScrollView {
					PostDetailContent(post: post,
                                      usedTo: usedTo)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                // MARK: iOS 16.4 미만
            } else {
                ViewThatFits(in: .vertical) {
                    PostDetailContent(post: post,
                                      usedTo: usedTo)
                        .frame(maxHeight: .infinity, alignment: .top)
                    ScrollView {
                        PostDetailContent(post: post,
                                          usedTo: usedTo)
                    }
                }
            }
            // 삭제 버튼 다이얼로그
            if isDeleteDialogPresented {
                CustomDialog(type: .twoButton(
                    message: "술상을 엎으시겠습니까?",
                    leftButtonLabel: "취소",
                    leftButtonAction: {
                        isDeleteDialogPresented = false
                    },
                    rightButtonLabel: "확인",
                    rightButtonAction: {
                        isDeleteDialogPresented = false
						Task {
							await postViewModel.deletePost(userID: post.postField.user.userID,
														   postID: post.postField.postID ?? "")
							// Post 실시간 처리로 인한 코드 주석처리
                            // await postViewModel.fetchFirstPost()
                            // TODO: - currentUser posts refetch
//                            await authViewModel.getCurrentUserPosts(uid: post.postField.user.userID)
                        }
                        navigationRouter.back()
                    })
                )
            }
		}
        .task {
            // shareLink 용 이미지 가져오기
            shareImage = await postViewModel.getPostThumbnailImage(url: post.postField.imagesURL.first)
        }
		.navigationBarBackButtonHidden()
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Button {
                    navigationRouter.back()
				} label: {
					Image(systemName: "chevron.left")
				}
                .disabled(isDeleteDialogPresented)
			}
			switch postUserType {
			case .writer:
				ToolbarItem(placement: .topBarTrailing) {
					// 공유하기
                    ShareLink(item: "\(post.postField.user.userName)님의 술상",
							  subject: Text("이 링크를 확인해보세요."),
							  message: Text("주다 - JUDA 에서 술상 게시글을 공유했어요!"),
							  // 미리보기
							  preview: SharePreview(
                                Text("\(post.postField.user.userName)님의 술상"),
								image: shareImage)
					) {
						Image(systemName: "square.and.arrow.up")
					}
				}
                ToolbarItem(placement: .topBarTrailing) {
                    // 게시글 수정하기
                    NavigationLink(value: Route.Record(recordType: .edit)) {
                        Image(systemName: "pencil")
                            .task {
                                recordViewModel.post = post
                            }
                    }
                }
				ToolbarItem(placement: .topBarTrailing) {
                    // 게시글 삭제하기
					Button {
						isDeleteDialogPresented = true
					} label: {
						Image(systemName: "trash")
					}
				}
			case .reader:
				ToolbarItem(placement: .topBarTrailing) {
					// 공유하기
                    ShareLink(item: "\(post.postField.user.userName)님의 술상",
                              subject: Text("이 링크를 확인해보세요."),
                              message: Text("주다 - JUDA 에서 술상 게시글을 공유했어요!"),
                              // 미리보기
                              preview: SharePreview(
                                Text("\(post.postField.user.userName)님의 술상"),
                                image: shareImage)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
				}
				ToolbarItem(placement: .topBarTrailing) {
                    // 게시글 신고하기
					Button {
						// 버튼 탭 할 경우 신고뷰 출력
						isReportPresented = true
					} label: {
						Image(systemName: "light.beacon.max")
					}
				}
			}
		}
		.foregroundStyle(.mainBlack)
		// 신고뷰를 풀스크린커버로 아래에서 위로 올라오는 뷰
		.fullScreenCover(isPresented: $isReportPresented) {
			PostReportView(post: post, isReportPresented: $isReportPresented)
		}
	}
}

// MARK: - 술상 디테일에서, 스크롤 안에 보여줄 내용 부분
struct PostDetailContent: View {
	@EnvironmentObject private var postViewModel: PostViewModel
    
	let post: Post
	let usedTo: WhereUsedPostGridContent

    var body: some View {
        VStack {
            // Bar 형태로 된 게시글 정보를 보여주는 뷰
			PostInfo(post: post,
                     usedTo: usedTo)
			// 게시글의 사진을 페이징 스크롤 형식으로 보여주는 뷰
            PostPhotoScroll(postPhotosURL: post.postField.imagesURL)
			// 술 평가 + 글 + 음식 태그
			VStack(alignment: .leading, spacing: 20) {
				// 술 평가
				PostDrinkRating(post: post)
				CustomDivider()
				// 술상 글 내용
				Text(post.postField.content)
					.font(.regular16)
					.multilineTextAlignment(.leading)
				// 음식 태그
                PostTags(tags: post.postField.foodTags)
			}
			.padding(.horizontal, 20)
        }
    }
}

