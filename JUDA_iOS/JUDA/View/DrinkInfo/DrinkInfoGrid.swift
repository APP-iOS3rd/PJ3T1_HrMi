//
//  DrinkInfoGrid.swift
//  JUDA
//
//  Created by phang on 1/28/24.
//

import SwiftUI

// MARK: - 술장 그리드 뷰
struct DrinkInfoGrid: View {
    var body: some View {
        // MARK: iOS 16.4 이상
        if #available(iOS 16.4, *) {
            ScrollView() {
                DrinkGridContent()
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .scrollDismissesKeyboard(.immediately)
        // MARK: iOS 16.4 미만
        } else {
            ViewThatFits(in: .vertical) {
                DrinkGridContent()
                    .frame(maxHeight: .infinity, alignment: .top)
                ScrollView {
                    DrinkGridContent()
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
    }
}

// MARK: - 술장 그리드 뷰 내용
struct DrinkGridContent: View {
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    
    // 술 그리드 셀 2개 column
    private let columns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]
        
    var body: some View {
        // 그리드
        LazyVGrid(columns: columns, spacing: 10) {
            if !drinkViewModel.isLoading {
                ForEach(drinkViewModel.drinks, id: \.drinkField.drinkID) { drink in
                    NavigationLink(value: Route
                        .DrinkDetail(drink: drink)) {
							DrinkGridCell(drink: drink)
                                .task {
                                    if drink == drinkViewModel.drinks.last {
                                        await drinkViewModel.loadDrinksNextPage()
                                    }
                                }
                    }
                    .buttonStyle(EmptyActionStyle())
                }
            } else {
                ForEach(0..<10) { _ in
                    ShimmerDrinkGridCell()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

#Preview {
    DrinkInfoGrid()
}
