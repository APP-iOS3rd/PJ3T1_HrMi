//
//  NoticeView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/02/01.
//

import SwiftUI

// MARK: - 공지사항 화면
struct NoticeView: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter

    var body: some View {
        VStack {
            Text("공지사항 뷰입니다. ")
				.font(.medium18)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigationRouter.back()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .tint(.mainBlack)
            }
            ToolbarItem(placement: .principal) {
                Text("공지사항")
                    .font(.medium16)
                    .foregroundStyle(.mainBlack)
            }
        }
    }
}
