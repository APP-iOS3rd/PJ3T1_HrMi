//
//  PostSearchList.swift
//  JUDA
//
//  Created by Minjae Kim on 2/26/24.
//

import SwiftUI

struct PostSearchList: View {
	@EnvironmentObject private var postViewModel: PostViewModel
	let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            NavigationLink(value: Route
                .NavigationPostsTo(usedTo: .postSearch,
                                   searchTagType: .userName,
								   postSearchText: searchText, 
								   searchPosts: postViewModel.searchPostsByUserName)) {
                PostSearchListCell(searchTagType: .userName,
                                   searchText: searchText,
                                   postCount: postViewModel.searchPostsByUserName.count)
            }
            .disabled(postViewModel.searchPostsByUserName.isEmpty)
            .foregroundStyle(postViewModel.searchPostsByUserName.isEmpty ? .gray01 : .mainBlack)

            NavigationLink(value: Route
                .NavigationPostsTo(usedTo: .postSearch,
                                   searchTagType: .drinkTag,
								   postSearchText: searchText, 
								   searchPosts: postViewModel.searchPostsByDrinkTag)) {
                PostSearchListCell(searchTagType: .drinkTag,
                                   searchText: searchText,
                                   postCount: postViewModel.searchPostsByDrinkTag.count)
            }
            .disabled(postViewModel.searchPostsByDrinkTag.isEmpty)
            .foregroundStyle(postViewModel.searchPostsByDrinkTag.isEmpty ? .gray01 : .mainBlack)

            NavigationLink(value: Route
                .NavigationPostsTo(usedTo: .postSearch,
                                   searchTagType: .foodTag,
								   postSearchText: searchText, 
								   searchPosts: postViewModel.searchPostsByFoodTag)) {
                PostSearchListCell(searchTagType: .foodTag,
                                   searchText: searchText,
                                   postCount: postViewModel.searchPostsByFoodTag.count)
            }
            .disabled(postViewModel.searchPostsByFoodTag.isEmpty)
            .foregroundStyle(postViewModel.searchPostsByFoodTag.isEmpty ? .gray01 : .mainBlack)
            Spacer()
        }
        .padding(20)
    }
}
