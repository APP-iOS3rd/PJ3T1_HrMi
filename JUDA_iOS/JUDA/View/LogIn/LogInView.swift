//
//  LogInView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/01/24.
//


import SwiftUI
import AuthenticationServices

// MARK: - 로그인 화면
struct LogInView: View {
    @Environment (\.colorScheme) var systemColorScheme
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var colorScheme: SystemColorTheme
    
    @State private var nextView: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                //
                Spacer()
                // 로고 + 이름
                VStack(alignment: .center, spacing: 20) {
                    // 앱 아이콘
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
                    // 앱 이름
                    Text("주다 - JUDA")
                        .font(.semibold24)
                        .multilineTextAlignment(.center)
                }
                //
                Spacer()
                // 로그인 버튼
                VStack(spacing: 30) {
                    // 애플 로그인
                    SignInWithAppleButton(.signIn) { request in
                        authViewModel.handleSignInWithAppleRequest(request)
                    } onCompletion: { result in
                        authViewModel.handleSignInWithAppleCompletion(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme.selectedColor == .light ? .black : colorScheme.selectedColor == .dark ? .white : systemColorScheme == .light ? .black : .white)
                    .frame(height: 54)
                    // 구글 로그인
                    Button {
                        Task {
                            await authViewModel.signInWithGoogle()
                        }
                    } label: {
                        Image("googleLight")
                            .resizable()
                            .scaledToFit()
                    }
                    .frame(height: 54)
                }
                .frame(maxWidth: 220)
                //
                Spacer()
                //
                Text("2024, 주다 - JUDA all rights reserved.\nPowered by PJ4T7_HrMi")
                    .font(.thin12)
                    .multilineTextAlignment(.center)
            }
            if authViewModel.showError {
                CustomDialog(type: .oneButton(
                    message: authViewModel.errorMessage,
                    buttonLabel: "확인",
                    action: { authViewModel.showError = false })
                )
            }
        }
        // 로그인 도중에 생기는 로딩
        .loadingView($authViewModel.isLoading)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigationRouter.back()
                } label: {
                    Image(systemName: "chevron.backward")
                }
                .foregroundStyle(.mainBlack)
            }
        }
        // 로그인 완료 시, 화면 이동
        .onChange(of: authViewModel.signInStatus) { newValue in
            authViewModel.isLoading = false
            if newValue == true {
                // 기존 유저의 경우, 뒤로 가기 ( 로그인 이전 뷰로 이동 )
                navigationRouter.back()
            }
        }
        // 신규 유저의 경우, 이용약관 뷰 이동
        .onChange(of: authViewModel.isNewUser) { _ in
            authViewModel.isLoading = false
            if authViewModel.isNewUser == true {
                nextView = true
            }
        }
        .fullScreenCover(isPresented: $nextView) {
            TermsAndVerificationView()
        }
    }
}
