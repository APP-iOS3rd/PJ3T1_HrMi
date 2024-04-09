//
//  ChangeUserNameView.swift
//  JUDA
//
//  Created by 백대홍 on 1/31/24.
//

import SwiftUI
import FirebaseAuth

// MARK: - 유저 닉네임 수정 화면
struct ChangeUserNameView: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @FocusState var isFocused: Bool
    
    // 새롭게 변경할 user Name을 담는 프로퍼티
    @State private var userChangeNickName: String = ""
    @State private var isCompleted: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("수정할 닉네임을 작성해주세요")
                .font(.medium16)
                .frame(maxWidth: .infinity, alignment: .leading)
            // 유저 닉네임 수정 텍스트 필드
            HStack {
                TextField(authViewModel.currentUser?.userField.name ?? "",
                          text: $userChangeNickName)
                .font(.medium16)
                .foregroundStyle(.mainBlack)
                .focused($isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled() // 자동 수정 비활성화
                .onChange(of: userChangeNickName) { _ in
                    isCompleted = authViewModel.isChangeUserName(changeName: userChangeNickName)
                }
                Spacer()
                // 텍스트 한번에 지우는 xmark 버튼
                if !userChangeNickName.isEmpty {
                    Button {
                        isFocused = true
                        userChangeNickName = ""
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .foregroundColor(.gray01)
            .padding(.vertical, 15)
            .padding(.horizontal, 10)
            .background(.gray05)
            .clipShape(.rect(cornerRadius: 10))
            // 유저 닉네임 만족 기준
            if isFocused {
                if userChangeNickName.count <= 1 || userChangeNickName.count > 10 {
                    Text("닉네임을 2자~10자 이내로 적어주세요.")
                        .font(.light14)
                        .foregroundStyle(.mainAccent01)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if userChangeNickName == authViewModel.currentUser?.userField.name {
                    Text("현재 사용하고 있는 닉네임입니다.")
                        .font(.light14)
                        .foregroundStyle(.mainAccent01)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            // spacer 대용 (키보드 숨기기 onTapGesture 영역)
            Rectangle()
                .fill(.background)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            //
            CustomDivider()
            // 닉네임 변경 완료
            Button {
                Task {
                    isFocused = false
                    await authViewModel.updateUserName(userName: userChangeNickName)
                    navigationRouter.back()
                }
            } label: {
                Text("변경 완료")
                    .font(.medium20)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                
            }
            .disabled(!isCompleted)
            .foregroundColor(isCompleted ? .white : .gray01)
            .buttonStyle(.borderedProminent)
            .tint(.mainAccent03)
        }
        .onTapGesture {
            isFocused = false
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigationRouter.back()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
            ToolbarItem(placement: .principal) {
                Text("닉네임 수정")
                    .font(.medium16)
            }
        }
        .tint(.mainBlack)
    }
}
