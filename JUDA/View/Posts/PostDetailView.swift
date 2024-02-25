//
//  PostDetailView.swift
//  JUDA
//
//  Created by Minjae Kim on 1/29/24.
//

import SwiftUI

enum PostUserType {
	case writter, reader
}

// MARK: - 술상 디테일 화면
struct PostDetailView: View {
	@EnvironmentObject private var postsViewModel: PostsViewModel
	@Environment(\.dismiss) var dismiss
	
	let postUserType: PostUserType
	let post: Post

	let postPhotos: [(imageID: String, uiImage: UIImage)]
	
	@State private var isReportPresented = false
	@State private var isDeleteDialogPresented = false
    
	var body: some View {
        ZStack {
            // 사용자, 글 정보 + 이미지 + 술 태그 + 글 내용 + 음식 태그
            // MARK: iOS 16.4 이상
            if #available(iOS 16.4, *) {
                ScrollView {
					PostDetailContent(post: post, postPhotos: postPhotos)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                // MARK: iOS 16.4 미만
            } else {
                ViewThatFits(in: .vertical) {
					PostDetailContent(post: post, postPhotos: postPhotos)
                        .frame(maxHeight: .infinity, alignment: .top)
                    ScrollView {
						PostDetailContent(post: post, postPhotos: postPhotos)
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
                        // TODO: write view dismiss code
						Task {
							guard let userID = post.userField.userID,
								  let postID = post.postField.postID else {
								return
							}
							await postsViewModel.postDelete(userID: userID, postID: postID)
						}
						dismiss()
                    })
                )
            }
		}
		.navigationBarBackButtonHidden()
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Button {
					dismiss()
				} label: {
					Image(systemName: "chevron.left")
				}
			}
			switch postUserType {
			case .writter:
				ToolbarItem(placement: .topBarTrailing) {
					// 공유하기
					ShareLink(item: "Test", // TODO: 실제 공유하려는 내용으로 변경 필요
							  subject: Text("이 링크를 확인해보세요."),
							  message: Text("주다 앱에서 술상 게시물을 공유했어요!"),
							  // 미리보기
							  preview: SharePreview(
								Text("\(post.userField.name)님의 술상"), // TODO: 해당 게시물 이름으로 변경
								image: Image("foodEx1")) // TODO: 해당 술상의 이미지로 변경
					) {
						Image(systemName: "square.and.arrow.up")
					}
				}
//				ToolbarItem(placement: .topBarTrailing) {
//                    // TODO: NavigationLink - value 로 수정
//					NavigationLink {
//                        RecordView(recordType: RecordType.edit)
//					} label: {
//						Image(systemName: "pencil")
//					}
//				}
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						isDeleteDialogPresented = true
					} label: {
						Image(systemName: "trash")
					}
				}
			case .reader:
				ToolbarItem(placement: .topBarTrailing) {
					// 공유하기
					ShareLink(item: "Test", // TODO: 실제 공유하려는 내용으로 변경 필요
							  subject: Text("이 링크를 확인해보세요."),
							  message: Text("주다 앱에서 술상을 공유했어요!"),
							  // 미리보기
							  preview: SharePreview(
								Text("\(post.userField.name)님의 술상"), // TODO: 해당 게시물 이름으로 변경
								image: Image("foodEx1")) // TODO: 해당 술상의 이미지로 변경
					) {
						Image(systemName: "square.and.arrow.up")
					}
				}
				ToolbarItem(placement: .topBarTrailing) {
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
			PostReportView(isReportPresented: $isReportPresented)
		}
	}
}

// MARK: - 술상 디테일에서, 스크롤 안에 보여줄 내용 부분
struct PostDetailContent: View {
	@EnvironmentObject private var postsViewModel: PostsViewModel
	let post: Post
	let postPhotos: [(imageID: String, uiImage: UIImage)]
	
    var body: some View {
        VStack {
            // Bar 형태로 된 게시글 정보를 보여주는 뷰
			PostInfo(post: post)
			// 게시글의 사진을 페이징 스크롤 형식으로 보여주는 뷰
			PostPhotoScroll(postPhotos: postPhotos)
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

