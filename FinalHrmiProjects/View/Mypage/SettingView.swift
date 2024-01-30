//
//  SettingView.swift
//  FinalHrmiProjects
//
//  Created by 홍세희 on 2024/01/30.
//

import SwiftUI
import WebKit

struct SettingView: View {
    private let optionNameList = ["라이트 모드", "다크 모드", "시스템 모드"]
    private let urlStringList = [
        "https://bit.ly/HrmiService",
        "https://bit.ly/HrmiPrivacyPolicy",
        "https://bit.ly/HrmiLocationPolicy"
    ]
    
    @State private var isShowingSheet: Bool = false
    @State private var selectedSortingOption: String = "시스템 모드"
    
    @State private var isLogoutClicked = false // 로그아웃 버튼 클릭 시
    @State private var isDeletAccount = false // 회원탈퇴 버튼 클릭 시
    
    @State private var isShowServiceWebView = false // 서비스 이용약관 보여주기
    @State private var isShowPrivacyWebView = false // 개인 정보 처리 방침 보여주기
    @State private var isShowLocationWebView = false // 위치 정보 처리방침 보여주기
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(alignment: .leading) {
                    // MARK: 알림 설정
                    // TODO: 토글로 바꾸기
                    NavigationLink {
                        
                    } label: {
                        HStack {
                            Text("알림 설정")
                            Spacer()
                            Image(systemName: "chevron.forward")
                        }
                        .modifier(CustomText())
                    }
                    
                    // MARK: 화면 모드 설정
                    // 버튼 클릭 시 반짝이는 애니메이션 제거 코드 추가하기
                    Button(action: {
                        isShowingSheet.toggle()
                    }, label: {
                        HStack {
                            Text("화면 모드 설정")
                            Spacer()
                            // TODO: SettingView -> develop에 merge 후 커스텀 바텀 시트와 관련된 컴포넌트 수정 예정
                            // TODO: 선택 버튼 - gray01로 하기
                            // TODO: CustomBottomSheet -> contents 길이에 맞게 가변적으로 변경
                            CustomSortingButton(optionNameList: optionNameList, selectedSortingOption: $selectedSortingOption, isShowingSheet: $isShowingSheet)
                        }
                        .modifier(CustomText())
                    })
                    // MARK: 로그아웃
                    Button(action: {
                        isLogoutClicked.toggle() // 버튼 클릭 시, 커스텀 다이얼로그 활성화
                    }, label: {
                        Text("로그아웃")
                            .foregroundStyle(.mainAccent02)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    })
                    
                    // MARK: 회원탈퇴
                    Button(action: {
                        isDeletAccount.toggle() // 버튼 클릭 시, 커스텀 다이얼로그 활성화
                    }, label: {
                        Text("회원탈퇴")
                            .foregroundStyle(.mainAccent02)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    })
                    
                    CustomDivider()
                    
                    // MARK: 공지사항
                    NavigationLink {
                        NoticeView()
                    } label: {
                        HStack {
                            Text("공지사항")
                            Spacer()
                            Image(systemName: "chevron.forward")
                        }
                        .modifier(CustomText())
                        
                    }
                    
                    // MARK: 메일 문의하기
                    NavigationLink {
                        EmailContactView()
                    } label: {
                        HStack {
                            Text("메일 문의하기")
                            Spacer()
                            Image(systemName: "chevron.forward")
                        }
                        .modifier(CustomText())
                    }
                    
                    CustomDivider()
                    
                    // MARK: 서비스 이용약관
                    AppServiceInfoView(text: "서비스 이용약관", urlString: urlStringList[0], isShowWebView: $isShowServiceWebView)
                    
                    // MARK: 개인정보 처리방침
                    AppServiceInfoView(text: "개인정보 처리방침", urlString: urlStringList[1], isShowWebView: $isShowPrivacyWebView)
                    
                    // MARK: 위치정보 처리방침
                    AppServiceInfoView(text: "위치정보 처리방침", urlString: urlStringList[2], isShowWebView: $isShowLocationWebView)
        
                    // MARK: 버전 정보
                    Text("버전 정보 0.0.1")
                        .font(.regular16)
                        .foregroundStyle(.gray01)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    
                    CustomDivider()
                }
                // 화면 모드 설정 클릭 시 띄워지는 CustomBottomSheetView
                EnabledBottomSheetView(optionNameList: optionNameList, selectedSortingOption: $selectedSortingOption, isShowingSheet: $isShowingSheet)
                
                // 로그아웃 버튼 클릭 시 띄워지는 CustomAlert
                if isLogoutClicked {
                    CustomAlert(message: "로그아웃 하시겠습니까?", leftButtonLabel: "취소", leftButtonAction: {
                        isLogoutClicked.toggle()
                    }, rightButtonLabel: "로그아웃", rightButtonAction: {}) // TODO: 로그아웃 기능 추가하기
                }
                
                // 회원탈퇴 버튼 클릭 시 띄워지는 CustomAlert
                // TODO: 탈퇴 문구 수정하기
                if isDeletAccount {
                    CustomAlert(message: "탈퇴하시겠습니까?", leftButtonLabel: "취소", leftButtonAction: {
                        isDeletAccount.toggle()
                    }, rightButtonLabel: "탈퇴하기", rightButtonAction: {}) // TODO: 회원탈퇴 기능 추가하기
                }
            }
        }
    }
}

// 반복되는 UI 설정 ViewModifier를 통해 한꺼번에 묶기
struct CustomText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.regular16)
            .foregroundStyle(.mainBlack)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
    }
}


#Preview {
    SettingView()
}
