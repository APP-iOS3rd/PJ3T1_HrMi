//
//  NavigationRouter.swift
//  JUDA
//
//  Created by phang on 2/27/24.
//

import SwiftUI

// MARK: - 전체 Navigation 조정을 위한 Route
enum Route: Hashable {
    case Login
    case AddTag
    case AlarmStore
    case Setting
    case Notice
    case ChangeUserName
    case Record(recordType: RecordType)
    case NavigationProfile(userID: String,
                           usedTo: WhereUsedPostGridContent)
    case NavigationPosts(usedTo: WhereUsedPostGridContent,
                         searchTagType: SearchTagType?,
                         taggedPosts: [Post],
                         selectedDrinkName: String?,
                         selectedFoodTag: String?)
    case NavigationPostsTo(usedTo: WhereUsedPostGridContent,
                           searchTagType: SearchTagType,
                           postSearchText: String)
    case DrinkDetail(drink: Drink)
    case DrinkDetailWithUsedTo(drink: Drink,
                               usedTo: WhereUsedDrinkDetails)
    case PostDetail(postUserType: PostUserType,
                    post: Post,
                    usedTo: WhereUsedPostGridContent)
}

final class NavigationRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    func clear() {
        path = .init()
    }
    
    func back() {
        path.removeLast()
    }
    
    func push(to screen: Route) {
//        path.append(screen)
    }
}
