//
//  SearchTagView.swift
//  JUDA
//
//  Created by 정인선 on 1/30/24.
//

import SwiftUI

// MARK: - 술 태그 서치 시트 화면
// Defualt로 술찜 목록 보여주기
struct SearchTagView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var recordViewModel: RecordViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    // drink 검색 결과를 담은 배열
    @State var searchResult = [Drink]()
    // DrinkListCell 선택 후 CustomDialog에서 사용되는 점수
    @State private var rating: Double = 0
    // 서치바 Text
    @State private var tagSearchText = ""
    // CustomDialog - Rating 을 띄워주는 상태 프로퍼티
    @State private var isShowRatingDialog: Bool = false
    // SearchTagView Sheet를 띄워주는 상태 프로퍼티
    @Binding var isShowSearchTag: Bool
    // SearchBar의 Focus여부를 판별하는 FocusState
    @FocusState private var isFocused: Bool
	
    var body: some View {
        ZStack {
            VStack {
                // 서치바 + 시트 닫기 버튼
                HStack(alignment: .center, spacing: 0) {
                    // 서치바 submit 시, 술 검색
                    SearchBar(inputText: $tagSearchText, isFocused: $isFocused) {
                        Task {
                            searchResult = await drinkViewModel.getSearchedDrinks(from: tagSearchText)
                        }
                    }
                    // 서치바 Text가 없을 때, 술 검색 결과 비워주기
                    .onChange(of: tagSearchText) { _ in
                        if tagSearchText == "" {
                            searchResult = []
                        }
                    }
                    // Sheet 내려주기
                    Button {
                        isShowSearchTag.toggle()
                    } label: {
                        XmarkOnGrayCircle()
                            .font(.title)
                            .padding(.trailing, 15)
                    }
                }
                .padding(.top, 20)
                // 검색 텍스트 X
                if tagSearchText.isEmpty {
                    VStack {
                        Rectangle()
                            .fill(.background)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Text("술 이름을 검색해보세요.")
                            .font(.regular16)
                            .foregroundStyle(.gray01)
                        Rectangle()
                            .fill(.background)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                // 검색 중
                } else if drinkViewModel.isSearching {
                    VStack {
                        Rectangle()
                            .fill(.background)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        CircularLoaderView(size: 40)
                        Rectangle()
                            .fill(.background)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                // 검색 텍스트 O
                } else {
                    // MARK: iOS 16.4 이상
                    if #available(iOS 16.4, *) {
                        ScrollView() {
                            SearchTagListContent(isShowRatingDialog: $isShowRatingDialog, searchResult: searchResult)
                        }
                        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                        .scrollDismissesKeyboard(.immediately)
                    // MARK: iOS 16.4 미만
                    } else {
                        ViewThatFits(in: .vertical) {
                            SearchTagListContent(isShowRatingDialog: $isShowRatingDialog, searchResult: searchResult)
                                .frame(maxHeight: .infinity, alignment: .top)
                            ScrollView {
                                SearchTagListContent(isShowRatingDialog: $isShowRatingDialog, searchResult: searchResult)
                            }
                            .scrollDismissesKeyboard(.immediately)
                        }
                    }
                }
            }
            // 키보드 내리기
            .onTapGesture {
                isFocused = false
            }
            // CustomDialog - .rating
            if isShowRatingDialog {
                // 선택된 Cell의 술 정보 데이터를 잘 받아왔을 때
                if let selectedDrinkTag = recordViewModel.selectedDrinkTag {
                    CustomDialog(type: .rating(
                        // 선택된 술 정보의 술 이름
                        drinkName: selectedDrinkTag.drinkName,
                        leftButtonLabel: "취소",
                        leftButtonAction: {
                            // CustomRatingDialog 사라지게 하기
                            isShowRatingDialog = false
                        },
                        rightButtonLabel: "평가",
                        rightButtonAction: {
                            // 0보다 큰 점수를 매겼을 때 수정 버튼 동작
                            if rating > 0 {
                                // dirnkTag 값 변경
                                let drinkID = selectedDrinkTag.drinkID
                                let drinkName = selectedDrinkTag.drinkName
                                let drinkAmount = selectedDrinkTag.drinkAmount
                                
                                if let index = recordViewModel.drinkTags.firstIndex(where: { $0.drinkID == drinkID }) {
                                    recordViewModel.drinkTags[index] = DrinkTag(drinkID: drinkID,
                                                                                drinkName: drinkName,
                                                                                drinkAmount: drinkAmount,
                                                                                drinkRating: rating)
                                } else {
                                    recordViewModel.drinkTags.append(DrinkTag(drinkID: drinkID,
                                                                              drinkName: drinkName,
                                                                              drinkAmount: drinkAmount,
                                                                              drinkRating: rating))
                                }
                                // 변경 후 CustomRatingDialog, SearchTagView 사라지게 하기
                                isShowRatingDialog = false
                                isShowSearchTag.toggle()
                            }
                        },
                        rating: $rating)
                    )
                }
            }
        }
        // SearchTagView Disappear시, 검색 결과 비워주기
        .onDisappear {
            searchResult = []
        }
    }
}

// MARK: - 스크롤 뷰 or 뷰 로 보여질 태그 추가 시, DrinkListCell 리스트
struct SearchTagListContent: View {
    @EnvironmentObject private var recordViewModel: RecordViewModel
    // CustomDialog - Rating 상태 값 받기
    @Binding var isShowRatingDialog: Bool
    // drink 검색 결과 배열
    let searchResult: [Drink]
        
    var body: some View {
        LazyVStack {
            ForEach(searchResult, id: \.drinkField.drinkID) { drink in
                DrinkListCell(drink: drink, usedTo: .searchTag)
                    .onTapGesture {
                        // 현재 선택된 DrinkListCell의 술 정보를 받아오기
                        guard let drinkID = drink.drinkField.drinkID else { return }
                        recordViewModel.selectedDrinkTag = DrinkTag(drinkID: drinkID, drinkName: drink.drinkField.name, drinkAmount: drink.drinkField.amount, drinkRating: 0)
                        // CustomDialog - Rating 띄우기
                        isShowRatingDialog = true
                    }
            }
        }
    }
}
