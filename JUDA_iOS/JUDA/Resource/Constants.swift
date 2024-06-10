//
//  Constants.swift
//  JUDA
//
//  Created by phang on 3/18/24.
//

import Foundation

// ContentView ForEach문 내부 Image를 파라미터에 따라 처리해주기 위함
enum SymbolType {
    case sfSymbol, customSymbol
}

// ContentView ForEach문 내부 View 변경을 위함
enum ViewType {
    case main, drinkInfo, posts, liked, myPage
}

// MyPage 접근 등에서 User 가 본인인지 타유저인지 확인하기 위함
enum UserType {
    case user, otherUser
}

// 술상(게시글) 기록 타입 : 작성 or 수정
enum RecordType {
    case add, edit
}

// 술상(게시글) 접근 시, 해당 글의 작성자인지 아닌지 확인
enum PostUserType {
    case writer, reader
}

// cell - 좋아요 + / -
enum LikedActionType {
    case plus, minus
}

// StarRating 에서 사용 - 평점 Text 추가 여부 확인용 enum type
enum StarRatingType {
    case none, withText
}

// 바텀 시트 타입
enum BottomSheetType {
    static let drinkInfo = "정렬 옵션 설정" // DrinkInfoView에서 쓰는 bottomSheet
    static let displaySetting = "화면 모드 설정" // 'SettingView - 화면 모드 설정' 에서 쓰는 bottomSheet
}

// 술 or 술상(게시글) 찜 세그먼트 enum
enum LikedType: String, CaseIterable {
    case drink = "술찜 리스트"
    case post = "술상 리스트"
    // 리스트
    static let list: [LikedType] = LikedType.allCases
}

// DrinkInfoView 에서 술을 보여주는 방식 - 그리드 or 리스트 enum
enum DrinkInfoLayoutOption: String, CaseIterable {
    case gridStyle = "grid.style"
    case listStyle = "list.style"
    // 리스트
    static let list: [DrinkInfoLayoutOption] = DrinkInfoLayoutOption.allCases
}

// DrinkInfoView 에서 술 정렬 Option enum
enum DrinkSortType: String, CaseIterable {
    case popularity = "인기순"
    case highAlcoholContent = "도수 높은 순"
    case lowAlcoholContent = "도수 낮은 순"
    case highPrice = "가격 높은 순"
    case lowPrice = "가격 낮은 순"
    // 리스트
    static let list: [DrinkSortType] = DrinkSortType.allCases
}

// 술의 카테고리
enum DrinkType: String, CaseIterable {
    case all = "전체"
    case traditional = "우리술"
    case beer = "맥주"
    case wine = "와인"
    case whiskey = "위스키"
    // 리스트
    static let list: [DrinkType] = DrinkType.allCases
}

// Post - 술상 정렬 enum
enum PostSortType: String, CaseIterable {
    case popularity = "인기"
    case mostRecent = "최신"
    // 리스트
    static let list: [PostSortType] = PostSortType.allCases
}

// Post - 술상 검색 enum
enum SearchTagType: String, CaseIterable {
    case userName = "작성자"
    case drinkTag = "술 태그"
    case foodTag = "음식 태그"
    // 리스트
    static let list: [SearchTagType] = SearchTagType.allCases
}

// 성별 enum
enum Gender: String, CaseIterable {
    case male = "male"
    case female = "female"
    
    var koreanString: String {
        switch self {
        case .male: "남성"
        case .female: "여성"
        }
    }
    // 리스트
    static let list: [Gender] = Gender.allCases
}

// 회원 가입 시, 개인 정보 활용 동의 체크 or 프로필 설정 화면 처리용 enum
enum TermsOrVerification {
    case TermsOfService
    case ProfileSetting
}

// 회원 가입 시, 프로필 사진 및 정보 작성 뷰에서 사용될 focusField enum
enum ProfileSettingFocusField: Hashable {
    case name
    case birth
}

// 본인 인증 화면에서 사용될 focusField enum
enum VerificationFocusField: Hashable {
    case name
    case birthDate
    case genderNumber
    case phoneNumber
    case verificationNumber
}

// Fire Storage 의 폴더 타입 / 폴더 명
enum FireStorageFolderType: String {
    case user = "userImages"
    case post = "postImages"
    case drink = "drinkImages"
}

// fireauth - Auth Provider Option
enum AuthProviderOption: String {
    case apple = "apple.com"
    case google = "google.com"
    case email = "password"
}

// firestore 의 필드 명을 갖고 있는 - User Liked List (Posts / Drinks) Type
enum UserLikedListType: String {
    case posts = "likedPosts"
    case drinks = "likedDrinks"
}

// 유저의 나이 string 값 갖고 있는 enum
enum Age: String, CaseIterable {
    case twenty = "20"
    case thirty = "30"
    case fourty = "40"
    case fifty = "50"
}

// 어느 뷰에서 DrinkDetails 이 사용되는지 enum
enum WhereUsedDrinkDetails {
    case drinkInfo
    case post
    case liked
    case main
}

// 어느 뷰에서 DrinkListCell 이 사용되는지 enum
enum WhereUsedDrinkListCell {
    case drinkInfo
    case drinkSearch
    case searchTag
    case liked
    case main
}

// 어느 뷰에서 PostGridContent 이 사용되는지 enum
enum WhereUsedPostGridContent {
    case post
    case postSearch
    case drinkDetail
    case liked
    case myPage
    case main
}

// 닉네임 변경 & 생성 시 조건에 대한 enum
enum NickNameChange {
    case invalidLength
    case aleadyUsing
    case completed
    case userNotFound
}
