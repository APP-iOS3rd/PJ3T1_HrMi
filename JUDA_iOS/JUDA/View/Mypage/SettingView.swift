//
//  SettingView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/02/01.
//

import SwiftUI
import WebKit

// MARK: - 환경설정 세팅 화면
struct SettingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var colorScheme: SystemColorTheme
    
    private let optionNameList = ["라이트 모드", "다크 모드", "시스템 모드"] // 화면 모드 설정 옵션 이름 리스트
    private let webViewNameList = ["서비스 이용약관", "개인정보 처리방침", "위치정보 처리방침"] // 웹뷰로 보여줘야하는 항목 이름 리스트
    private let webViewurlList = ["https://bit.ly/HrmiService",
                                  "https://bit.ly/HrmiPrivacyPolicy",
                                  "https://bit.ly/HrmiLocationPolicy"] // webViewNameList에 해당하는 url 주소
    
    @AppStorage("selectedSortingOption") private var selectedSortingOption: String = "시스템 모드"
    @State private var isAlarmOn: Bool = false // 알람 설정 toggle
    @State private var isShowingSheet: Bool = false // CustomBottomSheet 올라오기
    @State private var isLogoutClicked = false // 로그아웃 버튼 클릭 시
    @State private var isDeletAccount = false // 회원탈퇴 버튼 클릭 시
    
    private var version: String? {
        guard let dictionary = Bundle.main.infoDictionary,
              let version = dictionary["CFBundleShortVersionString"] as? String else {return nil}
        return version // 1.0
    }
    
    private var build: String? {
        guard let dictionary = Bundle.main.infoDictionary,
              let build = dictionary["CFBundleVersion"] as? String else {return nil}
        return build // 1
    }
    
    var body: some View {
        // alarm 토글 버튼 액션 추가
        let alarmToggleBinding = Binding {
            isAlarmOn
        } set: {
            authViewModel.openAppSettings(notUsed: $0)
        }
        // View
        ZStack {
            VStack(alignment: .leading) {
                if authViewModel.signInStatus {
                    // 알림 설정
                    Toggle(isOn: alarmToggleBinding) {
                        Text("알림 설정")
                    }
                    .tint(.mainAccent03)
                    .modifier(CustomText())
                    //
                    CustomDivider()
                }
                
                // 화면 모드 설정
                // 버튼 클릭 시 반짝이는 애니메이션 제거 코드 추가하기
                Button {
                    isShowingSheet.toggle()
                } label: {
                    HStack {
                        Text("화면 모드 설정")
                        Spacer()
                        CustomSortingButton(optionNameList: optionNameList, selectedSortingOption: selectedSortingOption, isShowingSheet: $isShowingSheet)
                        // CustomSortingButton에서 선택한 selectedSortingOption로 화면 색상 설정하기
                            .onChange(of: selectedSortingOption) { _ in
                                switch selectedSortingOption {
                                case "라이트 모드":
                                    colorScheme.selectedColor = .light
                                case "다크 모드":
                                    colorScheme.selectedColor = .dark
                                case "시스템 모드":
                                    colorScheme.selectedColor = nil
                                default:
                                    break
                                }
                            }
                    }
                    .modifier(CustomText())
                }
                //
                if authViewModel.signInStatus {
                    // 로그아웃
                    Button {
                        isLogoutClicked.toggle() // 버튼 클릭 시, 커스텀 다이얼로그 활성화
                    } label: {
                        Text("로그아웃")
                            .font(.regular16)
                            .foregroundStyle(.mainAccent02)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background)
                    }
                    // 회원탈퇴
                    Button {
                        isDeletAccount.toggle() // 버튼 클릭 시, 커스텀 다이얼로그 활성화
                    } label: {
                        Text("회원탈퇴")
                            .font(.regular16)
                            .foregroundStyle(.mainAccent02)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background)
                    }
                    //
                    CustomDivider()
                }
                // 공지사항
                NavigationLink(value: Route.Notice) {
                    HStack {
                        Text("공지사항")
                        Spacer()
                        Image(systemName: "chevron.forward")
                    }
                    .modifier(CustomText())
                }
                //
                CustomDivider()
                // 이용약관 및 정보 처리 방침
                ForEach(0..<webViewNameList.count, id: \.self) { index in
                    AppServiceInfoView(text: webViewNameList[index], urlString: webViewurlList[index])
                }
                // 버전 정보
                Text("버전 정보 \(version ?? "1.0").\(build ?? "6")")
                    .font(.regular16)
                    .foregroundStyle(.gray01)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                //
                CustomDivider()
                Spacer()
            }
            // 화면 모드 설정 - CustomBottomSheet (.displaySetting)
            .sheet(isPresented: $isShowingSheet) {
                CustomBottomSheetContent(optionNameList: optionNameList,
                                         isShowingSheet: $isShowingSheet,
                                         selectedSortingOption: $selectedSortingOption,
                                         bottomSheetTypeText: BottomSheetType.displaySetting)
                .presentationDetents([.displaySetting])
                .presentationDragIndicator(.hidden) // 시트 상단 인디케이터 비활성화
                .interactiveDismissDisabled() // 내려서 닫기 비활성화
            }
            
            // 로그아웃 - CustomAlert
            if isLogoutClicked {
                CustomDialog(type: .twoButton(
                    message: "로그아웃 하시겠습니까?",
                    leftButtonLabel: "취소",
                    leftButtonAction: {
                        isLogoutClicked.toggle()
                    },
                    rightButtonLabel: "로그아웃",
                    rightButtonAction: {
                        Task {
                            // 로그아웃 - AppStorage 에서 변경
                            await authViewModel.signOut()
                            //
                            isLogoutClicked.toggle()
                            navigationRouter.back()
                            // MainView 로 보내기
                            appViewModel.selectedTabIndex = 0
                        }
                    })
                )
            }
            // 회원탈퇴 - CustomAlert
            if isDeletAccount {
                CustomDialog(type: .twoButton(
                    message: "탈퇴 하시겠습니까?",
                    leftButtonLabel: "취소",
                    leftButtonAction: {
                        isDeletAccount.toggle()
                    },
                    rightButtonLabel: "탈퇴하기",
                    rightButtonAction: {
                        Task {
                            if await authViewModel.deleteAccount() {
                                isDeletAccount.toggle()
                                navigationRouter.back()
                                // 메인 화면으로 이동
                                appViewModel.selectedTabIndex = 0
                            } else {
                                isDeletAccount.toggle()
                                authViewModel.errorMessage = "회원탈퇴에 문제가 발생했어요.\n다시 시도해주세요."
                                authViewModel.showError = true
                            }
                        }
                    })
                )
            }
            // 로그아웃 or 회원탈퇴 실패 시,
            if authViewModel.showError {
                CustomDialog(type: .oneButton(
                    message: authViewModel.errorMessage,
                    buttonLabel: "확인",
                    action: { authViewModel.showError = false }))
            }
        }
        // 앱 내에서 이동하지 않고, 설정에서만 변경 했을 수 있으니 onAppear 시 시스템 다시 확인하기
        .task {
            do {
                self.isAlarmOn = try await authViewModel.getSystemAlarmSetting()
            } catch {
                print("error :: getSystemAlarmSetting", error.localizedDescription)
            }
        }
        // 앱 설정으로 다녀왔을 때, 설정 체크
        .onChange(of: scenePhase) { newScenePhase in
            Task {
                switch newScenePhase {
                    // 앱이 백그라운드에서 포그라운드로 전환될 때 실행할 작업
                case .active:
                    do {
                        self.isAlarmOn = try await authViewModel.getSystemAlarmSetting()
                    } catch {
                        print("error :: getSystemAlarmSetting", error.localizedDescription)
                    }
                    // 그 외
                default:
                    break
                }
            }
        }
        // 회원탈퇴 시, 생기는 로딩
        .loadingView($authViewModel.isLoading)
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
                Text("설정")
                    .font(.medium16)
                    .foregroundStyle(.mainBlack)
            }
        }
    }
}

// 반복되는 UI 설정 ViewModifier를 통해 한꺼번에 묶기
private struct CustomText: ViewModifier {
	func body(content: Content) -> some View {
		content
			.font(.regular16)
			.foregroundStyle(.mainBlack)
			.padding(.horizontal, 20)
			.padding(.vertical, 10)
	}
}

