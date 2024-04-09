//
//  AuthenticatedMypageView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/01/24.
//

import SwiftUI
import FirebaseAuth

// MARK: - 마이페이지 탭
struct AuthenticatedMypageView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var recordViewModel: RecordViewModel
    
    var body: some View {
        VStack {
            // 프로필 사진 -- 닉네임 -- 수정
            UserProfileView(userType: .user)
            // 내가 작성한 게시물 -- '새 글 작성하기'
            HStack {
                Text("내가 작성한 술상")
                    .font(.semibold18)
                Spacer()
                NavigationLink(value: Route.AddTag) {
                    Text("술상 올리기")
                        .font(.medium16)
                        .foregroundStyle(.mainBlack)
                }
                .task {
                    recordViewModel.recordPostDataClear()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            if let user = authViewModel.currentUser,
                !user.posts.isEmpty {
                // 사용자가 작성한 글
                // MARK: iOS 16.4 이상
                if #available(iOS 16.4, *) {
                    ScrollView() {
                        PostGridContent(usedTo: .myPage, searchTagType: nil)
                    }
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                    // MARK: iOS 16.4 미만
                } else {
                    ViewThatFits(in: .vertical) {
                        PostGridContent(usedTo: .myPage, searchTagType: nil)
                            .frame(maxHeight: .infinity, alignment: .top)
                        ScrollView {
                            PostGridContent(usedTo: .myPage, searchTagType: nil)
                        }
                    }
                }
            } else {
                VStack {
                    Text("작성한 술상이 없어요!")
                        .font(.medium16)
                        .foregroundStyle(.mainBlack)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .task {
            await authViewModel.startListeningForUserField()
        }
    }
}
