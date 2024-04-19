//
//  ContentView.swift
//  JUDA
//
//  Created by 정인선 on 1/26/24.
//

import SwiftUI

// MARK: - 앱 전체 스타트 탭 뷰
struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
	@EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var colorScheme: SystemColorTheme

    // Tabbar 불투명하게 설정 (색상 백그라운드)
    init() {
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().isTranslucent = true
        UITabBar.appearance().backgroundColor = .systemBackground
    }
    
    var body: some View {
		TabView(selection: $appViewModel.selectedTabIndex) {
            ForEach(0..<TabItem.tabItems.count, id: \.self) { index in
                let item = TabItem.tabItems[index]
                tabItemView(viewType: item.viewType)
                    .tabItem {
                        // symbolType에 따라 Image 파라미터 다르게 생성
                        switch item.symbolType {
                            // 커스텀된 symbol일 때, Image(_: String) 사용
                        case .customSymbol:
                            Image(item.symbolName)
                            // 탭 선택 시, symbol fill로 변경되게 환경 변수 변경
								.environment(\.symbolVariants, appViewModel.selectedTabIndex == index ? .fill : .none)
                            // sf symbol 사용할 때, Image(systemName: String) 사용
                        case .sfSymbol:
                            Image(systemName: item.symbolName)
								.environment(\.symbolVariants, appViewModel.selectedTabIndex == index ? .fill : .none)
                        }
                        Text(item.name)
                            .font(.medium10)
                    }
                    .tag(index)
            }
        }
        // deepLink 통해서, url 의 host 에 따라 탭 이동.
        .onOpenURL { url in
            guard let tabID = url.tabIdentifier else { return }
            switch tabID {
            case .drinks:
				appViewModel.selectedTabIndex = 1
            case .posts:
				appViewModel.selectedTabIndex = 2
            }
        }
        .tint(.mainAccent03)
        // SettingView - 화면 모드 -> 선택한 옵션에 따라 배경색 변환
        .preferredColorScheme(colorScheme.selectedColor == .light ? .light : colorScheme.selectedColor == .dark ? .dark : nil)
    }
    
    // viewType에 따라 특정 View를 리턴해주는 함수
    @ViewBuilder
    private func tabItemView(viewType: ViewType) -> some View {
        switch viewType {
        case .main:
            MainView()
        case .drinkInfo:
            DrinkInfoView()
        case .posts:
            PostsView()
        case .liked:
            LikedView()
        case .myPage:
            MyPageView()
        }
    }
}

#Preview {
    ContentView()
}
