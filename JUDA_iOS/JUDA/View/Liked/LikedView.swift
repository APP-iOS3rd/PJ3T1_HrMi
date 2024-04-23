//
//  LikedView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/01/24.
//

import SwiftUI

// MARK: - 하트 누른 술 + 술상 볼 수 있는 탭
struct LikedView: View {
    @StateObject private var navigationRouter = NavigationRouter()
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var selectedSegmentIndex = 0
    
    var body: some View {
        NavigationStack(path: $navigationRouter.path) {
            VStack(spacing: 0) {
                // 세그먼트 (술찜 리스트 / 술상 리스트)
                CustomTextSegment(segments: LikedType.list.map { $0.rawValue },
                                  selectedSegmentIndex: $selectedSegmentIndex)
                .padding(.bottom, 14)
                .padding([.top, .horizontal], 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                // 술찜 or 술상 탭 뷰
                TabView(selection: $selectedSegmentIndex) {
                    ForEach(0..<LikedType.list.count, id: \.self) { index in
                        ScrollViewReader { value in
                            Group {
                                if LikedType.list[index] == .drink {
                                    if authViewModel.signInStatus {
                                        // 술찜 리스트
                                        LikedDrinkList()
                                    } else {
                                        VStack(spacing: 40) {
                                            Spacer()
                                            Text("로그인해서\n 내가 찜한 술을 확인할 수 있어요")
                                                .font(.semibold18)
                                                .foregroundStyle(.gray01)
                                                .multilineTextAlignment(.center)
                                            Spacer()
                                        }
                                    }
                                } else {
                                    if authViewModel.signInStatus {
                                        // 술상 리스트
                                        LikedPostGrid()
                                    } else {
                                        VStack(spacing: 40) {
                                            Spacer()
                                            Text("로그인해서\n 내가 찜한 술상을 확인할 수 있어요")
                                                .font(.semibold18)
                                                .foregroundStyle(.gray01)
                                                .multilineTextAlignment(.center)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .onChange(of: selectedSegmentIndex) { newValue in
                                value.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationDestination(for: Route.self) { value in
                switch value {
                case .AddTag:
                    AddTagView()
                        .modifier(TabBarHidden())
                case .NavigationProfile(let userID,
                                        let usedTo):
                    NavigationProfileView(userID: userID,
                                          usedTo: usedTo)
                case .Record(let recordType):
                    RecordView(recordType: recordType)
                case .ChangeUserName:
                    ChangeUserNameView()
                        .modifier(TabBarHidden())
                case .DrinkDetail(let drink):
                    DrinkDetailView(drink: drink)
                        .modifier(TabBarHidden())
                case .DrinkDetailWithUsedTo(let drink, let usedTo):
                    DrinkDetailView(drink: drink,
                                    usedTo: usedTo)
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
        .environmentObject(navigationRouter)
        .toolbar(appViewModel.tabBarState, for: .tabBar)
    }
}
