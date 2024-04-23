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
	@State private var navigationPostSelectedSegmentIndex = 0
	@State private var searchPosts: [Post] = [] // post 검색에 따른 Post 배열
	
	let usedTo: WhereUsedPostGridContent // 어떤 View에서 사용하는 지
	let searchTagType: SearchTagType? // 필터링 방식 => '작성자 이름' or '술 이름' or '음식 태그'

	var taggedPosts: [Post]? // drink detail 에서 받아올 Post 배열
	var selectedDrinkName: String? // drink detail 에서 받아올 술 이름
	var postSearchText: String? // post 검색 시 받아올 검색 키워드
	
	private var titleText: String {
		switch usedTo {
		case .postSearch:
			return postSearchText ?? ""
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
								  selectedSegmentIndex: $navigationPostSelectedSegmentIndex)
				.padding(.vertical, 14)
				.padding(.horizontal, 20)
				.frame(maxWidth: .infinity, alignment: .leading)
				// 인기 or 최신 탭뷰
				TabView(selection: $navigationPostSelectedSegmentIndex) {
					ForEach(0..<PostSortType.list.count, id: \.self) { index in
						ScrollViewReader { value in
							Group {
								if PostSortType.list[index] == .popularity {
									// 인기순
									PostGrid(usedTo: usedTo,
											 searchTagType: searchTagType,
											 postSearchText: postSearchText,
											 searchPosts: $searchPosts,
											 navigationPostSelectedSegmentIndex: $navigationPostSelectedSegmentIndex)
								} else {
									// 최신순
									PostGrid(usedTo: usedTo,
											 searchTagType: searchTagType,
											 postSearchText: postSearchText,
											 searchPosts: $searchPosts,
											 navigationPostSelectedSegmentIndex: $navigationPostSelectedSegmentIndex)
								}
							}
							.onChange(of: navigationPostSelectedSegmentIndex) { newValue in
								value.scrollTo(newValue, anchor: .center)
							}
						}
					}	
				}
        .tabViewStyle(.page(indexDisplayMode: .never))
				.ignoresSafeArea()
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
			// PostDetailView 에서 '음식 태그' 로 이동한 상태
			// 혹은
			// PostInfo 에서 '검색' 을 통해서 이동한 상태
			// 기본 인기순 정렬
			} else if usedTo == .postSearch,
					  let searchTagType = searchTagType,
					  let postSearchText = postSearchText {
				searchPosts = await postViewModel.getSearchedPosts(from: postSearchText, category: searchTagType)
				searchPosts = await postViewModel.sortedPosts(searchPosts, postSortType: .popularity)
			}
		}
		// 세그먼트 변경 시
		.onChange(of: navigationPostSelectedSegmentIndex) { newValue in
			// '태그된 게시물' 의 경우
			if usedTo == .drinkDetail {
				Task {
					postViewModel.drinkTaggedPosts = await postViewModel.sortedPosts(postViewModel.drinkTaggedPosts,
																	   postSortType: PostSortType.list[navigationPostSelectedSegmentIndex])
				}
			// '검색' or '음식 태그' 경우
			} else if usedTo == .postSearch {
				Task {
					searchPosts = await postViewModel.sortedPosts(searchPosts,
																  postSortType: PostSortType.list[navigationPostSelectedSegmentIndex])
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
