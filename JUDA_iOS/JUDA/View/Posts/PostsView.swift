//
//  PostsView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/01/24.
//

import SwiftUI

// MARK: - 술상 탭
struct PostsView: View {
    @StateObject private var navigationRouter = NavigationRouter()
	@EnvironmentObject private var appViewModel: AppViewModel
	@EnvironmentObject private var authViewModel: AuthViewModel
	@EnvironmentObject private var postViewModel: PostViewModel
    @EnvironmentObject private var recordViewModel: RecordViewModel
	
    @State private var postSearchText: String = ""
    
	@FocusState private var isFocused: Bool
	
	var body: some View {
        NavigationStack(path: $navigationRouter.path) {
            ZStack {
                VStack(spacing: 0) {
                    // 상단 서치바
                    SearchBar(inputText: $postSearchText, isFocused: $isFocused) {
                        Task(priority: .high) {
                            await postViewModel.getSearchedPosts(from: postSearchText)
                        }
                    }
                    // 서치바 Text가 없을 때, 게시글 검색 결과 비워주기
                    .onChange(of: postSearchText) { _ in
                        if postSearchText == "" {
                            postViewModel.searchPostsByUserName = []
                            postViewModel.searchPostsByDrinkTag = []
                            postViewModel.searchPostsByFoodTag = []
                        }
                    }
                    // MARK: 검색어 입력 중
                    if isFocused == true {
                        VStack {
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Text("술상을 검색해보세요.")
                                .font(.regular16)
                                .foregroundStyle(.gray01)
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        // MARK: 검색 중
                    } else if postViewModel.isSearching {
                        VStack {
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            CircularLoaderView(size: 40)
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        // MARK: 검색 완료 / 결과 X
                    } else if !postSearchText.isEmpty,
                              postViewModel.searchPostsByUserName.isEmpty,
                              postViewModel.searchPostsByDrinkTag.isEmpty,
                              postViewModel.searchPostsByFoodTag.isEmpty,
                              isFocused == false {
                        VStack {
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Text("검색된 술상이 없어요.")
                                .font(.regular16)
                                .foregroundStyle(.gray01)
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        // MARK: 검색 완료 / 결과 O
                    } else if !postSearchText.isEmpty,
                              isFocused == false {
                        PostSearchList(searchText: postSearchText)
                        // MARK: 검색 X
                    } else {
                        HStack(alignment: .center) {
                            // 인기, 최신 순으로 선택하여 정렬하기 위한 CustomSegment
                            CustomTextSegment(segments: PostSortType.list.map { $0.rawValue },
                                              selectedSegmentIndex: $postViewModel.selectedSegmentIndex)
                            .padding(.bottom, 14)
                            .padding(.top, 20)
                            //
                            Spacer()
                            NavigationLink(value: Route.AddTag) {
                                Text("술상 올리기")
                                    .font(.medium16)
                                    .foregroundStyle(.mainBlack)
                            }
                            // 비로그인 상태일 때 네비게이션링크 비활성화
                            .opacity(authViewModel.signInStatus ? 1.0 : 0.3)
                            .disabled(!authViewModel.signInStatus)
                            .task {
                                recordViewModel.recordPostDataClear()
                            }
                        }
                        .padding(.horizontal, 20)
                        // 인기 or 최신 탭뷰
                        TabView(selection: $postViewModel.selectedSegmentIndex) {
                            ForEach(0..<PostSortType.list.count, id: \.self) { index in
                                ScrollViewReader { value in
                                    Group {
                                        if PostSortType.list[index] == .popularity {
                                            // 인기순
                                            PostGrid(usedTo: .post, searchTagType: nil)
                                        } else {
                                            // 최신순
                                            PostGrid(usedTo: .post, searchTagType: nil)
                                        }
                                    }
                                    .onChange(of: postViewModel.selectedSegmentIndex) { newValue in
                                        value.scrollTo(newValue, anchor: .center)
                                    }
                                }
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
                // 로그인 다이얼로그
                if authViewModel.isShowLoginDialog {
                    CustomDialog(type: .navigation(
                        message: "로그인이 필요한 기능이에요.",
                        leftButtonLabel: "취소",
                        leftButtonAction: {
                            authViewModel.isShowLoginDialog = false
                        },
                        rightButtonLabel: "로그인",
                        navigationLinkValue: .Login))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self) { value in
                switch value {
                case .ChangeUserName:
                    ChangeUserNameView()
                case .AddTag:
                    AddTagView()
                        .modifier(TabBarHidden())
                case .Login:
                    LogInView()
                        .modifier(TabBarHidden())
                case .NavigationPosts(let usedTo,
                                      let searchTagType,
                                      let taggedPosts,
                                      let selectedDrinkName,
                                      let selectedFoodTag):
                    NavigationPostsView(usedTo: usedTo,
                                        searchTagType: searchTagType,
                                        taggedPosts: taggedPosts,
                                        selectedDrinkName: selectedDrinkName,
                                        selectedFoodTag: selectedFoodTag)
                case .NavigationPostsTo(let usedTo,
                                        let searchTagType,
                                        let postSearchText):
                    NavigationPostsView(usedTo: usedTo,
                                        searchTagType: searchTagType,
                                        postSearchText: postSearchText)
                    .modifier(TabBarHidden())
                case .NavigationProfile(let userID,
                                      let usedTo):
                    NavigationProfileView(userID: userID,
                                          usedTo: usedTo)
                case .Record(let recordType):
                    RecordView(recordType: recordType)
                //
                case .DrinkDetail(let drink):
                    DrinkDetailView(drink: drink)
                        .modifier(TabBarHidden())
                case .DrinkDetailWithUsedTo(let drink, let usedTo):
                    DrinkDetailView(drink: drink, usedTo: usedTo)
                        .modifier(TabBarHidden())
                //
                case .PostDetail(let postUserType,
                                 let post,
                                 let usedTo):
                    PostDetailView(postUserType: postUserType,
                                   post: post,
                                   usedTo: usedTo)
                    .modifier(TabBarHidden())
                default:
                    ErrorPageView()
                        .modifier(TabBarHidden())

                }
            }
			// 키보드 내리기
			.onTapGesture {
				isFocused = false
			}
			.task {
				if postViewModel.posts.isEmpty {
                    await postViewModel.fetchFirstPost()
				}
			}
            .onChange(of: postViewModel.selectedSegmentIndex) { _ in
				Task {
                    await postViewModel.fetchFirstPost()
				}
			}
			.onAppear {
				appViewModel.tabBarState = .visible
			}
            .onDisappear {
                authViewModel.isShowLoginDialog = false
            }
		}
        .environmentObject(navigationRouter)
        .toolbar(appViewModel.tabBarState, for: .tabBar)
	}
}

#Preview {
	PostsView()
}
