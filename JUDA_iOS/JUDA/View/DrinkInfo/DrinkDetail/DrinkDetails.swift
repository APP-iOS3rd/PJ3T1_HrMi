//
//  DrinkDetails.swift
//  JUDA
//
//  Created by phang on 1/30/24.
//

import SwiftUI
import Kingfisher

// MARK: - 술 디테일에서 보여주는 상단의 술 정보 부분 (이미지, 이름, 가격 등)
struct DrinkDetails: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var postViewModel: PostViewModel
	@State private var isLiked = false

	let drink: Drink
	let usedTo: WhereUsedDrinkDetails
	
	private let debouncer = Debouncer(delay: 0.5)
    
    var body: some View {
        // 술 정보 (이미지, 이름, 용량, 나라, 도수, 가격, 별점, 태그된 게시물)
        HStack(alignment: .center, spacing: 30) {
            // 술 이미지
            if let url = drink.drinkField.drinkImageURL {
                DrinkDetailsKFImage(url: url)
            } else {
                Text("No Image")
                    .font(.medium16)
                    .foregroundStyle(.mainBlack)
                    .frame(height: 180)
                    .padding(10)
                    .frame(width: 100)
            }
            // 이름, 나라, 도수, 가격, 별점, 태그된 게시물
            VStack(alignment: .leading, spacing: 6) {
				HStack(alignment: .top) {
					// 이름 + 용량
                    Text(drink.drinkField.name + " " + drink.drinkField.amount)
						.font(.semibold18)
						.foregroundStyle(.mainBlack)
						.lineLimit(2)
					
					Spacer()
					
					Button {
                        if authViewModel.signInStatus {
                            isLiked.toggle()
                            debouncer.call {
                                Task {
                                    await authViewModel.updateLikedDrinks(isLiked: isLiked,
                                                                          selectedDrink: drink)
                                }
                            }
                        } else {
                            authViewModel.isShowLoginDialog = true
                        }
					} label: {
						Image(systemName: isLiked ? "heart.fill" : "heart")
							.resizable()
							.frame(width: 16, height: 16)
							.foregroundStyle(isLiked ? .mainAccent01 : .gray01)
					}
				}
                // 종류, 도수
                HStack {
                    // 종류
                    Text(drink.drinkField.type)
                    // 도수
                    Text(Formatter.formattedABVCount(abv: drink.drinkField.alcohol))
                }
                // 나라, 지방
                HStack {
                    // 나라
                    Text(drink.drinkField.country)
                    if drink.drinkField.category == DrinkType.wine.rawValue,
                       let province = drink.drinkField.province {
                        Text(province) // 지방
                    }
                }
                .font(.regular16)
                // 가격
                Text(Formatter.formattedPriceToString(price: drink.drinkField.price))
                    .font(.regular16)
                // 별점
                StarRating(rating: drink.drinkField.rating, color: .mainAccent05,
                           starSize: .regular16, fontSize: .regular16, starRatingType: .withText)
                // 태그된 게시물
                if drink.taggedPosts.count > 0 {
                    NavigationLink(value: Route
                        .NavigationPosts(usedTo: .drinkDetail,
                                         searchTagType: nil,
                                         taggedPosts: drink.taggedPosts,
                                         selectedDrinkName: drink.drinkField.name,
                                         selectedFoodTag: nil)) {
                        Text("\(drink.taggedPosts.count)개의 태그된 게시물")
                            .font(.regular16)
                            .foregroundStyle(.gray01)
                            .underline()
                    }
                }  else {
                    Text("태그된 게시물 없음")
                        .font(.regular16)
                        .foregroundStyle(.gray01)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
		.task {
            if let user = authViewModel.currentUser {
                self.isLiked = user.likedDrinks.contains { $0 == drink }
            }
		}
    }
}

// MARK: - 술 리스트 셀 사용 KingFisher 이미지
struct DrinkDetailsKFImage: View {
    let url: URL
    
    var body: some View {
        KFImage.url(url)
            .placeholder {
                CircularLoaderView(size: 20)
                    .frame(height: 180)
                    .padding(10)
                    .frame(width: 100)
            }
            .loadDiskFileSynchronously(true) // 디스크에서 동기적으로 이미지 가져오기
            .cancelOnDisappear(true) // 화면 이동 시, 진행중인 다운로드 중단
            .cacheMemoryOnly() // 메모리 캐시만 사용 (디스크 X)
            .fade(duration: 0.2) // 이미지 부드럽게 띄우기
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 180)
            .padding(10)
            .frame(width: 100)
    }
}
