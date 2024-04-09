//
//  DrinkDetailView.swift
//  JUDA
//
//  Created by phang on 1/30/24.
//

import SwiftUI
import Kingfisher

// MARK: - 술 디테일 화면
struct DrinkDetailView: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var windowWidth: CGFloat = 0
    @State private var shareImage: Image = Image("AppIcon") // shareLink 용 이미지

    let drink: Drink
    var usedTo: WhereUsedDrinkDetails = .drinkInfo
    
    var body: some View {
        // 세로 스크롤
        ZStack {
            ScrollView {
                VStack(spacing: 10) {
                    // 술 정보 (이미지, 이름, 나라, 도수, 가격, 별점, 태그된 게시물)
                    DrinkDetails(drink: drink, usedTo: usedTo)
                    CustomDivider()
                    // 단맛 / 신맛 / 청량 / 바디 / 탄산  or  향 / 맛 / 여운
                    switch drink.drinkField.category {
                    case DrinkType.traditional.rawValue:
                        // 단맛 / 신맛 / 청량 / 바디 / 탄산
                        KoreanTastingNotes(sweet: drink.drinkField.sweet,
                                           sour: drink.drinkField.sour,
                                           refresh: drink.drinkField.refresh,
                                           bodyFeel: drink.drinkField.body,
                                           carbonated: drink.drinkField.carbonated)
                        CustomDivider()
                        // 재료
                        DrinkMaterial(material: drink.drinkField.material,
                                      windowWidth: windowWidth)
                    default:
                        // 향 / 맛 / 여운
                        TastingNotes(aroma: drink.drinkField.aroma,
                                     taste: drink.drinkField.taste,
                                     finish: drink.drinkField.finish)
                    }
                    CustomDivider()
                    // 잘어울리는 음식
                    WellMatched(windowWidth: windowWidth,
                                drinkName: drink.drinkField.name)
                    CustomDivider()
                    // 차트 - 선호하는 연령, 성별 ( 데이터 있을 때만 보여주기 )
                    if drink.genderPreference.female + drink.genderPreference.male > 0 {
                        PeferenceChart(ageGroupPieData:
                                        Formatter.getPieModelData(ageData: drink.agePreference),
                                       genderGroupPieData:
                                        Formatter.getPieModelData(genderData: drink.genderPreference))
                        CustomDivider()
                    }
                    // 태그된 인기 게시물
                    if drink.taggedPosts.count > 0 {
                        TaggedTrendingPosts(drink: drink)
                    }
                }
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
        .task {
            windowWidth = TagHandler.getScreenWidthWithoutPadding(padding: 20)
            // shareLink 용 이미지 가져오기
            shareImage = await drinkViewModel.getDrinkImage(url: drink.drinkField.drinkImageURL)
        }
        .onDisappear {
            authViewModel.isShowLoginDialog = false
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigationRouter.back()
                } label: {
                    Image(systemName: "chevron.backward")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                // 공유하기
                ShareLink(item: drink.drinkField.name,
                          subject: Text("이 링크를 확인해보세요."),
                          message: Text("주다 - JUDA 에서 술 정보를 공유했어요!"),
                          // 미리보기
                          preview: SharePreview(
                            Text(drink.drinkField.name + " " + drink.drinkField.amount),
                            image: shareImage)
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .tint(.mainBlack)
    }
}
