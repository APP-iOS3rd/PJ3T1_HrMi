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
    
    let usedTo: WhereUsedPostGridContent
	let searchTagType: SearchTagType?
    
    init(usedTo: WhereUsedPostGridContent = .post, searchTagType: SearchTagType?) {
        self.usedTo = usedTo
		self.searchTagType = searchTagType
    }
	
    var body: some View {
        // MARK: iOS 16.4 이상
        if #available(iOS 16.4, *) {
            ScrollView() {
				PostGridContent(usedTo: usedTo, searchTagType: searchTagType)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .scrollDismissesKeyboard(.immediately)
            .refreshable {
                await postViewModel.fetchFirstPost()
            }
        // MARK: iOS 16.4 미만
        } else {
            ViewThatFits(in: .vertical) {
				PostGridContent(usedTo: usedTo, searchTagType: searchTagType)
                    .frame(maxHeight: .infinity, alignment: .top)
                ScrollView {
					PostGridContent(usedTo: usedTo, searchTagType: searchTagType)
                }
                .scrollDismissesKeyboard(.immediately)
                .refreshable {
                    await postViewModel.fetchFirstPost()
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
    
    let usedTo: WhereUsedPostGridContent
	let searchTagType: SearchTagType?
    let userType: UserType
    
    init(usedTo: WhereUsedPostGridContent, searchTagType: SearchTagType?, userType: UserType = .user) {
        self.usedTo = usedTo
        self.searchTagType = searchTagType
        self.userType = userType
    }
	
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            if usedTo == .post {
                if !postViewModel.isLoading {
                    ForEach(postViewModel.posts, id: \.postField.postID) { post in
                        NavigationLink(value: Route
                            .PostDetail(postUserType: authViewModel.currentUser?.userField.userID == post.postField.user.userID ? .writer : .reader,
                                        post: post,
                                        usedTo: usedTo)) {
                            PostCell(usedTo: .post, post: post)
<<<<<<< 864b10c052d8eafda116c2341fc1c7486b1083e8
                                .task {
                                    if post == postViewModel.posts.last {
                                        await postViewModel.fetchNextPost()
                                    }
=======
                                .onTapGesture {
                                    authViewModel.isShowLoginDialog = true
>>>>>>> [Edit] Main, Drink 비로그인 시 로그인 뷰 이동
                                }
                        }
                        .buttonStyle(EmptyActionStyle())
                        // TODO: 비로그인 상태인 경우 눌렀을 때 로그인뷰로 이동
                        .disabled(!authViewModel.signInStatus)
                    }
				} else {
					ForEach(0..<10) { _ in
						ShimmerPostCell()
					}
				}
			} else if usedTo == .postSearch {
				if let searchTagType = searchTagType {
					switch searchTagType {
					case .userName:
                        ForEach(postViewModel.searchPostsByUserName, id: \.postField.postID) { post in
<<<<<<< 864b10c052d8eafda116c2341fc1c7486b1083e8
							NavigationLink(value: Route
                                .PostDetail(postUserType: authViewModel.currentUser?.userField.userID == post.postField.user.userID ? .writer : .reader,
                                            post: post,
                                            usedTo: usedTo)) {
								PostCell(usedTo: .postSearch, post: post)
							}
							.buttonStyle(EmptyActionStyle())
							// TODO: 비로그인 상태인 경우 눌렀을 때 로그인뷰로 이동
							.disabled(!authViewModel.signInStatus)
						}
					case .drinkTag:
						ForEach(postViewModel.searchPostsByDrinkTag, id: \.postField.postID) { post in
							NavigationLink(value: Route
                                .PostDetail(postUserType: authViewModel.currentUser?.userField.userID == post.postField.user.userID ? .writer : .reader,
                                            post: post,
                                            usedTo: usedTo)) {
								PostCell(usedTo: .postSearch, post: post)
							}
							.buttonStyle(EmptyActionStyle())
							// TODO: 비로그인 상태인 경우 눌렀을 때 로그인뷰로 이동
							.disabled(!authViewModel.signInStatus)
						}
					case .foodTag:
						ForEach(postViewModel.searchPostsByFoodTag, id: \.postField.postID) { post in
							NavigationLink(value: Route
                                .PostDetail(postUserType: authViewModel.currentUser?.userField.userID == post.postField.user.userID ? .writer : .reader,
                                            post: post,
                                            usedTo: usedTo)) {
								PostCell(usedTo: .postSearch, post: post)
							}
							.buttonStyle(EmptyActionStyle())
							// TODO: 비로그인 상태인 경우 눌렀을 때 로그인뷰로 이동
							.disabled(!authViewModel.signInStatus)
=======
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
					case .drinkTag:
						ForEach(postViewModel.searchPostsByDrinkTag, id: \.postField.postID) { post in
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
					case .foodTag:
						ForEach(postViewModel.searchPostsByFoodTag, id: \.postField.postID) { post in
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
>>>>>>> [Edit] Main, Drink 비로그인 시 로그인 뷰 이동
						}
					}
				}
			} else if usedTo == .postFoodTag {
				ForEach(postViewModel.searchPostsByFoodTag, id: \.postField.postID) { post in
					NavigationLink(value: Route
                        .PostDetail(postUserType: authViewModel.currentUser?.userField.userID == post.postField.user.userID ? .writer : .reader,
                                    post: post,
                                    usedTo: usedTo)) {
						PostCell(usedTo: .postSearch, post: post)
					}
					.buttonStyle(EmptyActionStyle())
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
