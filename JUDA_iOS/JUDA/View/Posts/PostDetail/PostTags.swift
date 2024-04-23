//
//  PostTags.swift
//  JUDA
//
//  Created by Minjae Kim on 1/29/24.
//

import SwiftUI

// MARK: - 술상 디테일에서, 음식 태그 부분
struct PostTags: View {
    @State private var windowWidth: CGFloat = 0
    let tags: [String]
	
	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			ForEach(TagHandler.getRows(tags: tags,
									   spacing: 15,
									   fontSize: 14,
									   windowWidth: windowWidth,
									   tagString: "# "), id: \.self) { row in
				HStack(spacing: 15) {
					ForEach(row, id: \.self) { tag in
                        NavigationLink(value: Route
							.NavigationPostsTo(usedTo: .postSearch,
											   searchTagType: .foodTag,
											   postSearchText: tag)) {
                            Text("# \(tag)")
                                .font(.semibold14)
                                .foregroundStyle(.mainAccent04)
                        }
					}
				}
			}
		}
		.frame(width: windowWidth, alignment: .leading)
		.task {
			windowWidth = TagHandler.getScreenWidthWithoutPadding(padding: 20)
		}
	}
}
