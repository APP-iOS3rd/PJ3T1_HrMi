//
//  NavigationProfileView.swift
//  JUDA
//
//  Created by 백대홍 on 2/4/24.
//

import SwiftUI

// MARK: - 네비게이션 이동 시, 유저 프로필 화면
struct NavigationProfileView: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    
    let userID: String
    let usedTo: WhereUsedPostGridContent
    // 해당 게시글의 작성자가 로그인한 유저인지 판별
    private var userType: UserType {
        userID == authViewModel.currentUser?.userField.userID ? .user : .otherUser
    }
    
    var body: some View {
        VStack {
            // 프로필 사진 -- 닉네임 -- 수정
            UserProfileView(userType: userType)
            // 내가 작성한 게시물 -- 술상 올리기
            HStack {
                userType == .user ? Text("내가 작성한 술상") : Text("\(userViewModel.user?.userField.name ?? "") 님이 작성한 술상")
                    .font(.semibold18)
                Spacer()
                
                if userType == .user {
                    NavigationLink(value: Route.AddTag) {
                        Text("술상 올리기")
                            .font(.light14)
                            .foregroundStyle(.mainBlack)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            // 사용자가 작성한 글
            // MARK: iOS 16.4 이상
            if #available(iOS 16.4, *) {
                ScrollView() {
                    PostGridContent(usedTo: .myPage,
                                    searchTagType: nil,
                                    userType: userType)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                // MARK: iOS 16.4 미만
            } else {
                ViewThatFits(in: .vertical) {
                    PostGridContent(usedTo: .myPage,
                                    searchTagType: nil,
                                    userType: userType)                 
                    .frame(maxHeight: .infinity, alignment: .top)
                    ScrollView {
                        PostGridContent(usedTo: .myPage,
                                        searchTagType: nil,
                                        userType: userType)
                    }
                }
            }
        }
        //
        .task {
            switch userType {
            case .user:
                await authViewModel.startListeningForUserField()
            case .otherUser:
                await userViewModel.getUser(uid: userID)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigationRouter.back()
                } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(Color.mainBlack)
                }
            }
            ToolbarItem(placement: .principal) {
                userType == .user ? Text("마이페이지") : Text("\(userViewModel.user?.userField.name ?? "") 님의 페이지")
                    .font(.medium16)
            }
        }
        .navigationBarBackButtonHidden()
    }
}

