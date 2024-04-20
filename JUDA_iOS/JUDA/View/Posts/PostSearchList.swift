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
								   postSearchText: searchText)) {
                PostSearchListCell(searchTagType: .userName,
                                   searchText: searchText,
								   postCount: postViewModel.searchPostsByUserNameCount)
            }
			.disabled(postViewModel.searchPostsByUserNameCount == 0 ? true : false)
            .foregroundStyle(postViewModel.searchPostsByUserNameCount == 0 ? .gray01 : .mainBlack)

            NavigationLink(value: Route
                .NavigationPostsTo(usedTo: .postSearch,
                                   searchTagType: .drinkTag,
								   postSearchText: searchText)) {
                PostSearchListCell(searchTagType: .drinkTag,
                                   searchText: searchText,
                                   postCount: postViewModel.searchPostsByDrinkTagCount)
            }
            .disabled(postViewModel.searchPostsByDrinkTagCount == 0 ? true : false)
            .foregroundStyle(postViewModel.searchPostsByDrinkTagCount == 0 ? .gray01 : .mainBlack)

            NavigationLink(value: Route
                .NavigationPostsTo(usedTo: .postSearch,
                                   searchTagType: .foodTag,
								   postSearchText: searchText)) {
                PostSearchListCell(searchTagType: .foodTag,
                                   searchText: searchText,
                                   postCount: postViewModel.searchPostsByFoodTagCount)
            }
			.disabled(postViewModel.searchPostsByFoodTagCount == 0 ? true : false)
            .foregroundStyle(postViewModel.searchPostsByFoodTagCount == 0 ? .gray01 : .mainBlack)
            Spacer()
        }
        .padding(20)
    }
}
