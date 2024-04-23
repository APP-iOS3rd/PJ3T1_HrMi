//
//  ErrorPageView.swift
//  JUDA
//
//  Created by phang on 2/27/24.
//

import SwiftUI

struct ErrorPageView: View {
    @Environment (\.colorScheme) var systemColorScheme
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var colorScheme: SystemColorTheme

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Spacer()
            if .light == colorScheme.selectedColor ||
                (colorScheme.selectedColor == nil && systemColorScheme == .light) {
                Image("JUDA_AppLogo_ver1")
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: 290)
                    .cornerRadius(10)
            } else {
                Image("JUDA_AppLogo_ver1_Dark")
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: 290)
                    .cornerRadius(10)
            }
            Text("잘못된 페이지 요청입니다 🥲 🍸")
            Spacer()
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
            ToolbarItem(placement: .principal) {
                Text("🍺 404 Not Found 🍺")
            }
        }
        .tint(.mainBlack)
    }
}
