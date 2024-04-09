//
//  AlarmStoreView.swift
//  JUDA
//
//  Created by phang on 1/31/24.
//

import SwiftUI
import FirebaseAuth

// MARK: - 알람 쌓여있는 리스트 화면
struct AlarmStoreView: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 0) {
            if let user = authViewModel.currentUser,
               !user.notifications.isEmpty {
                // 알람 리스트
                // MARK: iOS 16.4 이상
                if #available(iOS 16.4, *) {
                    ScrollView() {
                        AlarmListContent()
                    }
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                    // MARK: iOS 16.4 미만
                } else {
                    ViewThatFits(in: .vertical) {
                        AlarmListContent()
                            .frame(maxHeight: .infinity, alignment: .top)
                        ScrollView {
                            AlarmListContent()
                        }
                    }
                }
            } else {
                VStack {
                    Text("아직 도착한 알람이 없어요!")
                        .font(.medium16)
                        .foregroundStyle(.mainBlack)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
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
                Text("알림")
                    .font(.medium16)
                    .foregroundStyle(.mainBlack)
            }
        }
    }
}

// MARK: - 스크롤 뷰 or 뷰 로 보여질 알람 리스트
private struct AlarmListContent: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        if let user = authViewModel.currentUser {
            LazyVStack {
                ForEach(user.notifications.indices, id: \.self) { index in
                    let alarm = user.notifications[index]
                    NavigationLink(value: Route.PostDetail(
                        postUserType: .writer,
                        post: alarm.likedPost,
                        usedTo: .myPage)) {
                            AlarmStoreListCell(alarm: alarm)
                        }
                    if alarm != user.notifications.last {
                        CustomDivider()
                    }
                }
            }
        }
    }
}
