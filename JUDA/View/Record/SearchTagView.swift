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
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var recordViewModel: RecordViewModel
    // TODO: 데이터 타입 변경 필요
    // CostomRatingDialog를 띄워주는 상태 프로퍼티
    @State private var isShowRatingDialog: Bool = false
    // SearchTagView Sheet를 띄워주는 상태 프로퍼티
    @Binding var isShowSearchTag: Bool
    // 점수
    @State private var rating: Double = 0
    // 서치바 Text
	@State private var tagSearchText = ""
	
    var body: some View {
        ZStack {
            VStack {
                // 서치바 + 시트 닫기 버튼
                HStack(alignment: .center, spacing: 0) {
                    // 서치바 submit 시, 술 검색
                    SearchBar(inputText: $tagSearchText) {
                        Task {
                            await recordViewModel.searchDrinkTags(text: tagSearchText)
                        }
                    }
                    // 서치바 Text가 없을 때, 술 검색 결과 비워주기
                    .onChange(of: tagSearchText) { _ in
                        if tagSearchText == "" {
							recordViewModel.searchDrinks.removeAll()
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
                // 찜 목록이 없을 때, 임의의 리스트 보여주기
                if tagSearchText.isEmpty {
                    Spacer()
                    Text("술 이름을 검색해보세요.")
                        .font(.regular14)
                        .foregroundStyle(.gray01)
                    Spacer()
                } else {
                    // MARK: iOS 16.4 이상
                    if #available(iOS 16.4, *) {
                        ScrollView() {
                            SearchTagListContent(isShowRatingDialog: $isShowRatingDialog)
                        }
                        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                        .scrollDismissesKeyboard(.immediately)
                    // MARK: iOS 16.4 미만
                    } else {
                        ViewThatFits(in: .vertical) {
                            SearchTagListContent(isShowRatingDialog: $isShowRatingDialog)
                                .frame(maxHeight: .infinity, alignment: .top)
                            ScrollView {
                                SearchTagListContent(isShowRatingDialog: $isShowRatingDialog)
                            }
                            .scrollDismissesKeyboard(.immediately)
                        }
                    }
                }
            }
            // CustomDialog - .rating
            if isShowRatingDialog {
                // 선택된 Cell의 술 정보 데이터를 잘 받아왔을 때
                if let selectedDrinkTag = recordViewModel.selectedDrinkTag {
                    CustomDialog(type: .rating(
                        // 선택된 술 정보의 술 이름
						drinkName: selectedDrinkTag.drink.name,
                        leftButtonLabel: "취소",
                        leftButtonAction: {
                            // CustomRatingDialog 사라지게 하기
                            isShowRatingDialog.toggle()
                        },
                        rightButtonLabel: "평가",
                        rightButtonAction: {
                            // 0보다 큰 점수를 매겼을 때 수정 버튼 동작
                            if rating > 0 {
                                // dirnkTag 값 변경
								if let index = recordViewModel.drinkTags.firstIndex(where: { $0.drink.drinkID == selectedDrinkTag.drink.drinkID }) {
									recordViewModel.drinkTags[index] = DrinkTag(drink: selectedDrinkTag.drink, rating: rating)
								} else {
									recordViewModel.drinkTags.append(DrinkTag(drink: selectedDrinkTag.drink, rating: rating))
								}
                                // 변경 후 CustomRatingDialog, SearchTagView 사라지게 하기
                                isShowRatingDialog.toggle()
                                isShowSearchTag.toggle()
                            }
                        },
                        rating: $rating)
                    )
                }
            }
        }
        // drinks collection all data fetch
        // users likedDrinks drink ID fetch
        .task {
            await recordViewModel.fetchDrinkData()
            await recordViewModel.fetchUserLikedDrinksID(uid: auth.uid)
        }
    }
}

// MARK: - 스크롤 뷰 or 뷰 로 보여질 태그 추가 시, 찜 목록이 있을 때 DrinkListCell 리스트
// TODO: 찜목록 불러와서 Default로 띄워주기
struct SearchTagListContent: View {
    @EnvironmentObject private var recordViewModel: RecordViewModel
    // CostomRatingDialog를 띄워주는 상태 프로퍼티
    @Binding var isShowRatingDialog: Bool
        
    var body: some View {
        LazyVStack {
			ForEach(recordViewModel.searchDrinks, id: \.drinkID) { drink in
				DrinkListCell(drink: drink,
                              isLiked: recordViewModel.userLikedDrinksID.contains(where: { $0 == drink.drinkID }),
                              searchTag: true)
                    .onTapGesture {
                        // 현재 선택된 DrinkListCell의 술 정보를 받아오기
						recordViewModel.selectedDrinkTag = DrinkTag(drink: drink, rating: 0)
                        // CustomRatingDialog 띄우기
                        isShowRatingDialog.toggle()
                    }
            }
        }
    }
}
