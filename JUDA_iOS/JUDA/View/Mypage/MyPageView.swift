//
//  MyPageView.swift
//  JUDA
//
//  Created by phang on 2/27/24.
//

import SwiftUI

// MARK: - My Page View
struct MyPageView: View {
    @StateObject private var navigationRouter = NavigationRouter()
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack(path: $navigationRouter.path) {
            VStack {
                if authViewModel.signInStatus {
                    AuthenticatedMypageView()
                } else {
                    UnauthenticatedMypageView()
                }
            }
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("마이페이지")
                        .font(.semibold18)
                }
                if authViewModel.signInStatus {
                    // 알람 모아보는 뷰
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(value: Route.AlarmStore) {
                            Image(systemName: "bell")
                        }
                    }
                }
                // 환경설정 세팅 뷰
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: Route.Setting) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .foregroundStyle(.mainBlack)
            .navigationDestination(for: Route.self) { value in
                switch value {
                case .ChangeUserName:
                    ChangeUserNameView()
                        .modifier(TabBarHidden())
                case .AddTag:
                    AddTagView()
                        .modifier(TabBarHidden())
                case .AlarmStore:
                    AlarmStoreView()
                        .modifier(TabBarHidden())
                case .Setting:
                    SettingView()
                        .modifier(TabBarHidden())
                case .Login:
                    LogInView()
                        .modifier(TabBarHidden())
                case .Notice:
                    NoticeView()
                case .NavigationProfile(let userID,
                                        let usedTo):
                    NavigationProfileView(userID: userID,
                                          usedTo: usedTo)
                case .Record(let recordType):
                    RecordView(recordType: recordType)
                case .DrinkDetail(let drink):
                    DrinkDetailView(drink: drink)
                        .modifier(TabBarHidden())
                case .DrinkDetailWithUsedTo(let drink, let usedTo):
                    DrinkDetailView(drink: drink, usedTo: usedTo)
                        .modifier(TabBarHidden())
                case .PostDetail(let postUserType,
                                 let post,
                                 let usedTo):
                    PostDetailView(postUserType: postUserType,
                                   post: post,
                                   usedTo: usedTo)
                    .modifier(TabBarHidden())
                default:
                    ErrorPageView()
                        .modifier(TabBarHidden())
                }
            }
            .onAppear {
                appViewModel.tabBarState = .visible
            }
        }
        .toolbar(appViewModel.tabBarState, for: .tabBar)
        .environmentObject(navigationRouter)
    }
}
