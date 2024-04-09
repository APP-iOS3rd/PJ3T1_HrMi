//
//  DrinkGridCell.swift
//  JUDA
//
//  Created by phang on 1/25/24.
//

import SwiftUI
import Kingfisher

// MARK: - 술 그리드 셀
struct DrinkGridCell: View {
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    let drink: Drink
    @State private var isLiked: Bool = false
    
    private let debouncer = Debouncer(delay: 0.5)
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            // 하트
            Button {
                if authViewModel.signInStatus {
                    isLiked.toggle()
                    // 디바운서 콜
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
                    .foregroundStyle(isLiked ? .mainAccent02 : .gray01)
            }
            // 술 정보
            VStack(alignment: .leading, spacing: 10) {
                // 술 사진
                VStack(alignment: .center) {
                    if let url = drink.drinkField.drinkImageURL {
                        KFImage.url(url)
                            .placeholder {
                                CircularLoaderView(size: 20)
                                    .frame(width: 70, height: 103.48)
                            }
                            .loadDiskFileSynchronously(true) // 디스크에서 동기적으로 이미지 가져오기
                            .cancelOnDisappear(true) // 화면 이동 시, 진행중인 다운로드 중단
                            .cacheMemoryOnly() // 메모리 캐시만 사용 (디스크 X)
                            .fade(duration: 0.2) // 이미지 부드럽게 띄우기
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 103.48)
                    } else {
                        Text("No Image")
                            .font(.medium16)
                            .foregroundStyle(.mainBlack)
                            .frame(width: 70, height: 103.48)
                    }
                }
                .frame(maxWidth: .infinity)
                // 술 이름 + 용량
                Text(drink.drinkField.name + " " + drink.drinkField.amount)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .font(.semibold16)
                    .foregroundStyle(.mainBlack)
                // 나라, 도수
                switch drink.drinkField.category {
                case DrinkType.wine.rawValue:
                    getCountryAndProvinceAndABV()
                default:
                    getCountryAndABV()
                }
                Spacer()
                // 별
                StarRating(rating: drink.drinkField.rating,
                           color: .mainAccent05,
                           starSize: .semibold14,
                           fontSize: .semibold14,
                           starRatingType: .withText)
            }
        }
        .frame(height: 270)
        .padding(10)
		.task {
            if let user = authViewModel.currentUser {
                self.isLiked = user.likedDrinks.contains { $0.drinkField.drinkID == drink.drinkField.drinkID }
            }
		}
    }
    
    @ViewBuilder
    private func getCountryAndABV() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(drink.drinkField.type)
                Text(Formatter.formattedABVCount(abv: drink.drinkField.alcohol))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(drink.drinkField.country)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.semibold14)
        .foregroundStyle(.gray01)
    }
    
    @ViewBuilder
    private func getCountryAndProvinceAndABV() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text(drink.drinkField.type)
                Text(Formatter.formattedABVCount(abv: drink.drinkField.alcohol))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 6) {
                Text(drink.drinkField.country)
                Text(drink.drinkField.province ?? "")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.semibold14)
        .foregroundStyle(.gray01)
    }
}
