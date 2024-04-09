//
//  UnauthenticatedMypageView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/02/20.
//

import SwiftUI

// MARK: - 로그인 X 일 경우 보여지는 MypageView
struct UnauthenticatedMypageView: View {
    var body: some View {
        VStack {
            HStack(spacing: 20) {
                Image("defaultprofileimage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
                    .frame(width: 70, height: 70)
                NavigationLink(value: Route.Login) {
                    Text("로그인 하러 가기 >")
                        .font(.medium18)
                        .foregroundStyle(.mainAccent03)
                }
                Spacer()
            }
            .padding()
            // 내가 작성한 게시물 -- '새 글 작성하기'
            HStack {
                Text("내가 작성한 술상")
                    .font(.semibold18)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            Text("로그인해서\n 술상을 작성해보세요")
                .font(.semibold18)
                .foregroundStyle(.gray01)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}
