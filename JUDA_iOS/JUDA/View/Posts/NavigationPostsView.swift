//
//  NavigationPostView.swift
//  JUDA
//
//  Created by Minjae Kim on 1/31/24.
//

import SwiftUI

// MARK: - 네비게이션 이동 시, 술상 화면
struct NavigationPostsView: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var postViewModel: PostViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
	@State private var selectedSegmentIndex = 0
    
	let usedTo: WhereUsedPostGridContent
	let searchTagType: SearchTagType?

    // drink detail 에서 올때 받아야 할 정보
    var taggedPosts: [Post]?
    var selectedDrinkName: String?
    // post detail 에서 올때 받아야 할 정보
	var selectedFoodTag: String?
    // post 검색 시 받아올 정보
    var postSearchText: String?
    
    var titleText: String {
        switch usedTo {
        case .postSearch:
            return postSearchText ?? ""
        case .postFoodTag:
            return selectedFoodTag ?? ""
        case .drinkDetail:
            return selectedDrinkName ?? ""
        default:
            return ""
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                // 세그먼트 (인기 / 최신)
                CustomTextSegment(segments: PostSortType.list.map { $0.rawValue },
                                  selectedSegmentIndex: $selectedSegmentIndex)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                // 인기 or 최신 탭뷰
                TabView(selection: $selectedSegmentIndex) {
                    ForEach(0..<PostSortType.list.count, id: \.self) { index in
                        ScrollViewReader { value in
                            Group {
                                if PostSortType.list[index] == .popularity {
                                    // 인기순
                                    PostGrid(usedTo: usedTo, searchTagType: searchTagType)
                                } else {
                                    // 최신순
                                    PostGrid(usedTo: usedTo, searchTagType: searchTagType)
                                }
                            }
                            .onChange(of: selectedSegmentIndex) { newValue in
                                value.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea()
                }
            }
            
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
        // 데이터 정렬
        .task {
            // DrinkDetailView 에서 '태그된 게시물' 받아온 상태 / 기본 인기순 정렬
            if usedTo == .drinkDetail,
               let taggedPosts = taggedPosts {
                postViewModel.drinkTaggedPosts = await postViewModel.sortedPosts(taggedPosts,
                                                                   postSortType: .popularity)
            // PostDetailView 에서 '음식 태그' 로 이동한 상태 / 기본 인기순 정렬
            } else if usedTo == .postFoodTag,
                      let selectedFoodTag = selectedFoodTag,
                      let searchTagType = searchTagType {
                // TODO: - 여기 넘어와서 검색하는게 맞나 고민
                await postViewModel.getSearchedPosts(from: selectedFoodTag)
                await postViewModel.sortedSearchedPosts(searchTagType: searchTagType,
                                                        postSortType: .popularity)
            // PostInfo 에서 '검색' 을 통해서 이동한 상태 / 기본 인기순 정렬
            } else if usedTo == .postSearch,
                      let searchTagType = searchTagType {
                await postViewModel.sortedSearchedPosts(searchTagType: searchTagType,
                                                        postSortType: .popularity)
            }
        }
        // 세그먼트 변경 시
        .onChange(of: selectedSegmentIndex) { newValue in
            // '태그된 게시물' 의 경우
            if usedTo == .drinkDetail {
                Task {
                    postViewModel.drinkTaggedPosts = await postViewModel.sortedPosts(postViewModel.drinkTaggedPosts,
                                                                       postSortType: PostSortType.list[selectedSegmentIndex])
                }
            // '검색' or '음식 태그' 경우
            } else if let searchTagType = searchTagType {
                Task {
                    await postViewModel.sortedSearchedPosts(searchTagType: searchTagType,
                                                            postSortType: PostSortType.list[selectedSegmentIndex])
                }
            }
        }
        .onDisappear {
            authViewModel.isShowLoginDialog = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigationRouter.back()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .principal) {
                Text(titleText)
                    .font(.medium16)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.mainBlack)
    }
}
