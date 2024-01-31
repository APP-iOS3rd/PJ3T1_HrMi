//
//  PostsView.swift
//  FinalHrmiProjects
//
//  Created by 홍세희 on 2024/01/24.
//

import SwiftUI

import SwiftUI

struct PostsView: View {
	
	@Binding var postSearchText: String
	
	@State private var selectedSegmentIndex = 0
	
	@State private var isLike = false
	@State private var likeCount = 45
	
	var body: some View {
		VStack {
			// 상단 태그 검색바
			SearchBar(inputText: $postSearchText)
			
			HStack {
				// 인기, 최신 순으로 선택하여 정렬하기 위한 CustomSegment
				CustomTextSegment(segments: PostOrLiked.post,
								  selectedSegmentIndex: $selectedSegmentIndex)
				.frame(width: 88)
				
				Spacer()
				
				// TODO: navigationLink 및 navigationDestination을 통한 RecordView 전환 구현
				NavigationLink {
					Text("새글 작성하기")
				} label: {
					Text("새글 작성하기")
						.font(.medium16)
						.foregroundStyle(.mainBlack)
				}
			}
			.padding(20)
			
			PagerView(pageCount: PostOrLiked.post.count, currentIndex: $selectedSegmentIndex) {
				ForEach(0..<PostOrLiked.post.count, id: \.self) { index in
					ScrollViewReader { value in
						Group {
							if index == 0 {
								// 인기순
								PostGrid(isLike: $isLike, likeCount: $likeCount, postUserType: .reader)
							} else {
								// 최신순
								PostGrid(isLike: $isLike, likeCount: $likeCount, postUserType: .writter)
							}
						}
						.onChange(of: selectedSegmentIndex) { newValue in
							withAnimation() {
								value.scrollTo(newValue, anchor: .center)
							}
						}
					}
				}
			}
			.ignoresSafeArea()
		}
	}
}

#Preview {
	PostsView(postSearchText: .constant(""))
}
