//
//  ProfileSettingView.swift
//  JUDA
//
//  Created by phang on 2/15/24.
//

import SwiftUI
import PhotosUI

// MARK: - 신규 유저의 경우, 프로필 사진 및 정보 작성 뷰
struct ProfileSettingView: View {
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel

    @FocusState var focusedField: ProfileSettingFocusField?

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var userProfileImage: UIImage? // 사용자 프로필 이미지
    
    @State private var name: String = ""
    var namePlaceholder: String {
        guard let user = authViewModel.currentUser else { return "닉네임" }
        return user.userField.name
    }
    @State private var birthDate: String = ""
    @State private var selectedGender: Gender?
    
    // 이미지 가져오다가 에러나면 띄워줄 alert
    @State private var isShowAlertDialog = false
    
    var nameReference: Bool {
        focusedField == .name && (name.count <= 1 || name.count > 10)
    }

    // 상위 뷰 체인지를 위함
    @Binding var viewType: TermsOrVerification
    // 알림 동의
    @Binding var notificationAllowed: Bool
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 30) {
                // 상단 바
                ZStack(alignment: .leading) {
                    // 뒤로가기
                    Button {
                        viewType = .TermsOfService
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.medium16)
                    }
                    // 타이틀
                    Text("프로필 설정")
                        .font(.medium16)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 10)
                .foregroundStyle(.mainBlack)
                ScrollView {
                    // 프로필 사진 선택
                    ZStack(alignment: .bottomTrailing) {
                        // 프로필 사진
                        if let image = userProfileImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(Circle())
                                .frame(width: 150, height: 150)
                        } else {
                            Image("defaultprofileimage")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipShape(Circle())
                                .frame(width: 150, height: 150)
                        }
                        LibraryPhotosPicker(selectedPhotos: $selectedPhotos, maxSelectionCount: 1) { // 최대 1장
                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.gray01)
                        }
                        .onChange(of: selectedPhotos) { _ in
                            Task {
                                do {
                                    userProfileImage = try await authViewModel.updateImage(selectedPhotos: selectedPhotos)
                                } catch {
                                    // 이미지 로드 실패 alert 띄워주기
                                    isShowAlertDialog = true
                                }
                            }
                        }
                        .tint(.mainBlack)
                    }
                    // 닉네임
                    VStack(alignment: .leading, spacing: 10) {
                        // Text
                        Text("닉네임")
                            .font(.semibold16)
                            .foregroundStyle(.mainBlack)
                        // 텍스트 필드
                        HStack {
                            TextField("닉네임", text: $name,
                                      prompt: Text(namePlaceholder))
                            .font(.medium16)
                            .foregroundStyle(.mainBlack)
                            .focused($focusedField, equals: .name)
                            .keyboardType(.default)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled() // 자동 수정 비활성화
                            Spacer()
                            // 텍스트 한번에 지우는 xmark 버튼
                            if !name.isEmpty && focusedField == .name {
                                Button {
                                    name = ""
                                } label: {
                                    Image(systemName: "xmark")
                                }
                                .foregroundStyle(.gray01)
                            }
                        }
                        // 텍스트 필드 언더라인
                        Rectangle()
                            .fill(.gray02)
                            .frame(height: 1)
                        // 닉네임 만족 기준
                        Text("닉네임을 2자~10자 이내로 적어주세요.")
                            .font(.light14)
                            .foregroundStyle(nameReference ? .mainAccent01 : .clear)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    // 생일 + 성별
                    HStack(alignment: .bottom) {
                        // 생일
                        VStack(alignment: .leading, spacing: 10) {
                            // Text
                            Text("생년월일")
                                .font(.semibold16)
                                .foregroundStyle(.mainBlack)
                            // 텍스트 필드
                            TextField("ex: 930715", text: $birthDate)
                                .font(.medium16)
                                .foregroundStyle(.mainBlack)
                                .focused($focusedField, equals: .birth)
                                .keyboardType(.numberPad)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled() // 자동 수정 비활성화
                            // 텍스트 필드 언더라인
                            Rectangle()
                                .fill(.gray02)
                                .frame(height: 1)
                        }
                        // 성별
                        HStack(alignment: .center, spacing: 10) {
                            ForEach(Gender.list, id: \.self) { gender in
                                ZStack {
                                    Rectangle()
                                        .fill(.background)
                                        .frame(width: 80, height: 40)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedGender == gender ? .mainAccent03 : .gray02,
                                                        lineWidth: 1)
                                        }
                                    Text(gender.koreanString)
                                        .font(selectedGender == gender ? .medium16 : .regular16)
                                        .foregroundStyle(selectedGender == gender ? .mainAccent03 : .mainBlack)
                                }
                                .onTapGesture {
                                    selectedGender = gender
                                }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                // 키보드 숨기기
                .onTapGesture {
                    focusedField = nil
                }
                // "완료" 버튼
                Button {
                    Task {
                        await authViewModel
                            .signInDoneButtonTapped(
                                name: name,
                                age: Formatter.calculateAge(birthdate: birthDate) ?? 20,
                                profileImage: userProfileImage,
                                gender: selectedGender!.rawValue,
                                notification: notificationAllowed
                            )
                        authViewModel.isLoading = false
                        navigationRouter.clear()
                    }
                } label: {
                    Text("완료")
                        .font(.medium20)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mainAccent03)
                // 모든 정보 입력 시, 버튼 보이도록
                .disabled(name.isEmpty || birthDate.isEmpty || selectedGender == nil)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 20)
            // 생일 6글자 치면 끝
            .onChange(of: birthDate) { _ in
                if birthDate.count == 6 {
                    focusedField = nil
                }
            }
            // 텍스트필드에서 엔터 시, 이동
            .onSubmit {
                switch focusedField {
                case .name:
                    focusedField = .birth
                default:
                    focusedField = nil
                }
            }
            // 사진 불러오기 실패 alert
            if isShowAlertDialog {
                CustomDialog(type: .oneButton(
                    message: "사진을 불러오는데 실패했어요\n다시 시도해주세요",
                    buttonLabel: "확인",
                    action: {
                        isShowAlertDialog = false
                    })
                )
            }
        }
        // 회원 가입 시, 로딩 뷰
        .loadingView($authViewModel.isLoading)
    }
}
