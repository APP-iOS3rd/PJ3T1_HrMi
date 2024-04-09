//
//  AddTagView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/01/24.
//

import SwiftUI
import PhotosUI

// MARK: - 글 작성 시, 사진 선택 및 술 태그 추가 화면
struct AddTagView: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var recordViewModel: RecordViewModel
    // 사진 배열
    @State private var selectedPhotos: [PhotosPickerItem] = []
    // SearchTagView Sheet를 띄워주는 상태 프로퍼티
	@State private var isShowSearchTag = false
    // CustomDialog - oneButton 을 띄워주는 상태 프로퍼티
	@State private var isShowAlertDialog: Bool = false
    // 숱 태그가 5개를 넘어가는지 확인하는 상태 프로퍼티
    @State private var isTagsCountAboveFive: Bool = false
    // 평점을 담아주는 프로퍼티
    @State private var rating: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack {
                    // 사진 선택 및 선택된 사진을 보여주는 수평 스크롤 이미지 뷰
                    PhotoSelectPagingTab(selectedPhotos: $selectedPhotos, isShowAlert: $isShowAlertDialog, imageSize: geo.size.width)
                    // 술 태그 추가 버튼
                    Button {
                        // 클릭 시 SearchTagView Sheet 띄워주기
                        isShowSearchTag.toggle()
                    } label: {
                        Text("술 태그 추가하기")
                            .font(.medium20)
                            .foregroundStyle(isTagsCountAboveFive ? .gray01 : .mainAccent03)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isTagsCountAboveFive ? .gray01 : .mainAccent03, lineWidth: 1)
                            }
                    }
                    .disabled(isTagsCountAboveFive)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    // 술 태그가 없을 때, 텍스트 보여주기
                    if recordViewModel.drinkTags.isEmpty {
                        Spacer()
                        Text("태그를 추가해보세요\n(최대 5개)")
                            .foregroundStyle(.gray01)
                            .font(.regular16)
                            .multilineTextAlignment(.center)
                        Spacer()
                    } else {
                        // 술 태그가 있을 때, DrinkTagCellScrollView 보여주기
                        // DrinkTagScroll 내부 Cell을 탭하면 CustomRatingDialog 띄워주기 위한 상태 프로퍼티 파라미터로 넘기기
                        DrinkTagScroll()
                    }
                }
                // CustomDialog - .rating
                if recordViewModel.isShowRatingDialog {
                    CustomDialog(type: .rating(
                        // 선택된 술 태그의 술 이름
                        drinkName: recordViewModel.selectedDrinkTag?.drinkName ?? "",
                        leftButtonLabel: "취소",
                        leftButtonAction: {
                            // CustomRatingDialog 사라지게 하기
                            recordViewModel.isShowRatingDialog = false
                        },
                        rightButtonLabel: "수정",
                        rightButtonAction: {
                            // 0보다 큰 점수를 매겼을 때 수정 버튼 동작
                            if rating > 0 {
                                // 술 태그 배열에서 해당 술 태그의 점수를 변경
								if let selectedDrinkTag = recordViewModel.selectedDrinkTag,
                                   let index = recordViewModel.drinkTags.firstIndex(where: { $0.drinkID ==  selectedDrinkTag.drinkID }) {
                                    recordViewModel.drinkTags[index] = DrinkTag(drinkID: selectedDrinkTag.drinkID, drinkName: selectedDrinkTag.drinkName, drinkAmount: selectedDrinkTag.drinkAmount, drinkRating: rating)
                                }
                                // 점수 변경 후 CustomRatingDialog 사라지게 하기
                                recordViewModel.isShowRatingDialog = false
                            }
                        },
                        // 선택된 술 태그의 점수를 CustomDialog에 반영해서 띄워주기 위함
                        rating: $rating)
                    )
                    // 선택한 drinkTag의 rating을 CustomDialog에 표시하기 위한 rating 값 변경
                    .onAppear {
                        if let rating = recordViewModel.selectedDrinkTag?.drinkRating {
                            self.rating = rating
                        }
                    }

                }
                // 상태 프로퍼티에 따라 CustomDialog - oneButton 띄워주기
                if isShowAlertDialog {
                    CustomDialog(type: .oneButton(
                        message: "사진을 불러오는데 실패했어요\n다시 시도해주세요",
                        buttonLabel: "확인",
                        action: {
                            isShowAlertDialog = false
                        })
                    )
                }
            }
            // 술 태그 리스트에 변화가 있을 때, 체크
            .onChange(of: recordViewModel.drinkTags.count) { _ in
                // 태그가 5개를 넘어가는지 확인
                calculateIsTagsCountAboveFive()
            }
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navigationRouter.back()
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .foregroundStyle(.mainBlack)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.Record(recordType: .add)) {
                        Text("다음")
                            .font(.regular16)
                    }
                    // 선택된 사진이 없을 때, 다음 페이지 이동 불가
                    .foregroundStyle(!selectedPhotos.isEmpty ? .mainBlack : .gray01)
                    .disabled(selectedPhotos.isEmpty)
                }
            }
            // SearchTageView Sheet 띄워주기
            .sheet(isPresented: $isShowSearchTag) {
                SearchTagView(isShowSearchTag: $isShowSearchTag)
            }
        }
    }
    
    // 술 태그가 5개를 넘는지 확인하는 함수
    private func calculateIsTagsCountAboveFive() {
        self.isTagsCountAboveFive = recordViewModel.drinkTags.count >= 5
    }
}
