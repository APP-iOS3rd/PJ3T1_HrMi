//
//  DrinkListCell.swift
//  JUDA
//
//  Created by phang on 1/25/24.
//

import SwiftUI
import Kingfisher

// MARK: - 술 리스트 셀
struct DrinkListCell: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel

    let drink: Drink
    var usedTo: WhereUsedDrinkListCell = .drinkInfo
    
    @State private var isLiked = false
    
    private let debouncer = Debouncer(delay: 0.5)
    
    var body: some View {
        HStack(alignment: .top) {
            // 술 정보
            HStack(alignment: .center, spacing: 20) {
                // 술 사진
                if let url = drink.drinkField.drinkImageURL {
                    DrinkListCellKFImage(url: url)
                } else {
                    Text("No Image")
                        .font(.medium16)
                        .foregroundStyle(.mainBlack)
                        .frame(width: 70, height: 103.48)
                }
                // 술 이름 + 나라, 도수 + 별점
                VStack(alignment: .leading, spacing: 10) {
                    // 술 이름 + 용량
                    Text(drink.drinkField.name + " " + drink.drinkField.amount)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .font(.semibold16)
                        .foregroundStyle(.mainBlack)
                    // 나라, 도수
                    HStack(spacing: 0) {
                        Text(drink.drinkField.country)
                            .font(.semibold14)
                        if drink.drinkField.category == DrinkType.wine.rawValue,
                           let province = drink.drinkField.province {
                            Text(province)
                                .font(.semibold14)
                                .padding(.leading, 6)
                        }
                        Text(Formatter.formattedABVCount(abv: drink.drinkField.alcohol))
                            .font(.semibold14)
                            .padding(.leading, 10)
                    }
                    .foregroundStyle(.gray01)
                    // 별점
                    StarRating(rating: drink.drinkField.rating,
                               color: .mainAccent05,
                               starSize: .semibold14, 
                               fontSize: .semibold14,
                               starRatingType: .withText)
                }
            }
            Spacer()
            // 하트
            // searchTagView에서 사용 시, 버튼이 아닌 이미지 처리 / mainView 도 동일
            if usedTo == .searchTag {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(isLiked ? .mainAccent02 : .gray01)
            } else {
                Button {
                    if authViewModel.signInStatus {
                        isLiked.toggle()
                        // 디바운서 콜
                        debouncer.call {
                            // drinks/likedUsersID에 userID를 id로 가진 빈 document 추가/삭제
                            // user/likedDrinks는 클라우드 펑션으로 처리
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
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .frame(height: 130)
		.task {
            if let user = authViewModel.currentUser {
                self.isLiked = user.likedDrinks.contains { $0.drinkField.drinkID == drink.drinkField.drinkID }
            }
		}
    }
}

// MARK: - 술 리스트 셀 사용 KingFisher 이미지
struct DrinkListCellKFImage: View {
    let url: URL
    
    var body: some View {
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
    }
}
