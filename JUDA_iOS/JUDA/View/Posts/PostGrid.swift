//
//  PostGrid.swift
//  JUDA
//
//  Created by Minjae Kim on 1/30/24.
//

import SwiftUI

// MARK: - 스크롤 뷰 or 뷰 로 보여질 post grid
struct PostGrid: View {
	@EnvironmentObject private var postViewModel: PostViewModel
	
	@State private var scrollAxis: Axis.Set = .vertical
	@State private var vHeight = 0.0
	@Binding var searchPosts: [Post]
	@Binding var navigationPostSelectedSegmentIndex: Int
	
	let usedTo: WhereUsedPostGridContent
	let searchTagType: SearchTagType?
	let postSearchText: String?
	
	init(usedTo: WhereUsedPostGridContent = .post,
		 searchTagType: SearchTagType?,
		 postSearchText: String?,
		 searchPosts: Binding<[Post]>,
		 navigationPostSelectedSegmentIndex: Binding<Int>) {
		self.usedTo = usedTo
		self.searchTagType = searchTagType
		self.postSearchText = postSearchText
		self._searchPosts = searchPosts
		self._navigationPostSelectedSegmentIndex = navigationPostSelectedSegmentIndex
	}
	
	var body: some View {
		// MARK: iOS 16.4 이상
		if #available(iOS 16.4, *) {
			ScrollView() {
				PostGridContent(usedTo: usedTo, searchTagType: searchTagType, searchPosts: $searchPosts)
			}
			.scrollBounceBehavior(.basedOnSize, axes: .vertical)
			.scrollDismissesKeyboard(.immediately)
			.refreshable {
				if usedTo == .post {
					await postViewModel.fetchFirstPost()
				} else if usedTo == .postSearch, let searchTagType = searchTagType, let postSearchText = postSearchText {
					searchPosts = await postViewModel.getSearchedPosts(from: postSearchText, category: searchTagType)
					searchPosts = await postViewModel.sortedPosts(searchPosts,
																  postSortType: PostSortType.list[navigationPostSelectedSegmentIndex])
				}
			}
		// MARK: iOS 16.4 미만
		} else {
			ViewThatFits(in: .vertical) {
				PostGridContent(usedTo: usedTo, searchTagType: searchTagType, searchPosts: $searchPosts)
					.frame(maxHeight: .infinity, alignment: .top)
				ScrollView {
					PostGridContent(usedTo: usedTo, searchTagType: searchTagType, searchPosts: $searchPosts)
				}
				.scrollDismissesKeyboard(.immediately)
				.refreshable {
					if usedTo == .post {
						await postViewModel.fetchFirstPost()
                    } else if usedTo == .postSearch, let searchTagType = searchTagType, let postSearchText = postSearchText {
                        searchPosts = await postViewModel.getSearchedPosts(from: postSearchText, category: searchTagType)
                        searchPosts = await postViewModel.sortedPosts(searchPosts,
                                                                      postSortType: PostSortType.list[navigationPostSelectedSegmentIndex])
                    }
				}
			}
		}
	}
}

// MARK: - 스크롤 뷰 or 뷰 로 보여질 post grid 내용 부분
struct PostGridContent: View {
	@EnvironmentObject private var authViewModel: AuthViewModel
	@EnvironmentObject private var postViewModel: PostViewModel
	@EnvironmentObject private var userViewModel: UserViewModel
	
	@Binding var searchPosts: [Post]
	
	let usedTo: WhereUsedPostGridContent
	let searchTagType: SearchTagType?
	let userType: UserType
	
	init(usedTo: WhereUsedPostGridContent, searchTagType: SearchTagType?, userType: UserType = .user, searchPosts: Binding<[Post]>) {
		self.usedTo = usedTo
		self.searchTagType = searchTagType
		self.userType = userType
		self._searchPosts = searchPosts
	}
	
	var body: some View {
		LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
			if usedTo == .post {
				if !postViewModel.isLoading {
					ForEach(postViewModel.posts, id: \.postField.postID) { post in
						if authViewModel.signInStatus {
							NavigationLink(value: Route
								.PostDetail(postUserType: authViewModel.currentUser?.userField.userID == post.postField.user.userID ? .writer : .reader,
											post: post,
											usedTo: usedTo)) {
								PostCell(usedTo: .post, post: post)
									.task {
										if post == postViewModel.posts.last {
											await postViewModel.fetchNextPost()
										}
									}
							}
							.buttonStyle(EmptyActionStyle())
						} else {
							// 비로그인 상태인 경우 눌렀을 때 로그인뷰로 이동
							PostCell(usedTo: .post, post: post)
								.onTapGesture {
									authViewModel.isShowLoginDialog = true
								}
						}
					}
				} else {
					ForEach(0..<10) { _ in
						ShimmerPostCell()
					}
				}
			} else if usedTo == .postSearch {
                if !postViewModel.isLoading {
                    ForEach(searchPosts, id: \.postField.postID) { post in
                        if authViewModel.signInStatus {
                            NavigationLink(value: Route
                                .PostDetail(postUserType: authViewModel.currentUser?.userField.userID == post.postField.user.userID ? .writer : .reader,
                                            post: post,
                                            usedTo: usedTo)) {
                                PostCell(usedTo: .postSearch, post: post)
                            }
                                            .buttonStyle(EmptyActionStyle())
                        } else {
                            // 비로그인 상태인 경우 눌렀을 때 로그인뷰로 이동
                            PostCell(usedTo: .postSearch, post: post)
                                .onTapGesture {
                                    authViewModel.isShowLoginDialog = true
                                }
                        }
                    }
                } else {
                    ForEach(0..<10) { _ in
                        ShimmerPostCell()
                    }
                }
			} else if usedTo == .drinkDetail {
				if !postViewModel.isLoading {
					ForEach(postViewModel.drinkTaggedPosts, id: \.postField.postID) { post in
						if authViewModel.signInStatus {
							NavigationLink(value: Route
								.PostDetail(postUserType: authViewModel.currentUser?.userField.userID == post.postField.user.userID ? .writer : .reader,
											post: post,
											usedTo: usedTo)) {
								PostCell(usedTo: usedTo, post: post)
							}
							.buttonStyle(EmptyActionStyle())
						} else {
							PostCell(usedTo: usedTo, post: post)
								.onTapGesture {
									authViewModel.isShowLoginDialog = true
								}
						}
					}
				} else {
					ForEach(0..<6) { _ in
						ShimmerPostCell()
					}
				}
			} else if usedTo == .myPage {
				if !userViewModel.isLoading {
					if userType == .user {
						if let currentUser = authViewModel.currentUser, !currentUser.posts.isEmpty {
							ForEach(currentUser.posts, id: \.postField.postID) { post in
								NavigationLink(value: Route
									.PostDetail(postUserType: .writer,
												post: post,
												usedTo: usedTo)) {
									PostCell(usedTo: usedTo, post: post)
								}
							}
						}
					} else {
						if let user = userViewModel.user, !user.posts.isEmpty {
							ForEach(user.posts, id: \.postField.postID) { post in
								NavigationLink(value: Route
									.PostDetail(postUserType: .reader,
												post: post,
												usedTo: usedTo)) {
									PostCell(usedTo: usedTo, post: post)
								}
							}
						}
					}
				} else {
					ForEach(0..<4) { _ in
						ShimmerPostCell()
					}
				}
			}
		}
		.padding(.horizontal, 20)
	}
}
