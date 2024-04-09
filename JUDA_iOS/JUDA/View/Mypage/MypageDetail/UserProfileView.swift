//
//  UserProfileView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/02/01.
//

import SwiftUI
import PhotosUI
import Kingfisher

// MARK: - 유저 프로필 (사진, 닉네임, 닉네임 수정)
struct UserProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    
    // 라이브러리에서 이미지 선택 시 사용
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImage = UIImage()
    // 이미지 가져오다가 에러나면 띄워줄 alert
    @State private var showAlert = false
    
    let userType: UserType
    private var profileImageURL: URL? {
        switch userType {
        case .user:
            return authViewModel.currentUser?.userField.profileImageURL
        case .otherUser:
            return userViewModel.user?.userField.profileImageURL
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            HStack(alignment: .bottom, spacing: -15) {
                // 사용자 프로필 이미지
                if let profileImageURL = profileImageURL {
                    UserProfileKFImage(url: profileImageURL, userType: userType, selectedImage: selectedImage)
                } else {
                    // 사용자 지정 이미지가 없을 때 기본 이미지로 설정
                    Image("defaultprofileimage")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 70, height: 70)
                }
                // 프로필 사진 수정 버튼
                if userType == .user {
                    LibraryPhotosPicker(selectedPhotos: $selectedPhotos, maxSelectionCount: 1) { // 최대 1장
                        Image(systemName: "pencil.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.gray01)
                    }
                    .onChange(of: selectedPhotos) { _ in
                        Task {
                            do {
                                let uiImage = try await authViewModel.updateImage(selectedPhotos: selectedPhotos)
                                self.selectedImage = uiImage
                                let url = await authViewModel.uploadProfileImageToStorage(image: uiImage)
                                if authViewModel.currentUser?.userField.profileImageURL == nil {
                                    await authViewModel.updateUserProfileImageURL(url: url)
                                }
                            } catch {
                                // 이미지 로드 실패 alert 띄워주기
                                showAlert = true
                            }
                        }
                    }
                    .tint(.mainBlack)
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("사진을 불러오는데 실패했어요\n다시 시도해주세요"),
                              dismissButton: .default(Text("확인"), action: { showAlert = false }))
                    }
                }
            }
            // 사용자 닉네임 표시
            Text(userType == .user ? authViewModel.currentUser?.userField.name ?? "" : userViewModel.user?.userField.name ?? "" )
            .font(.medium18)
            
            Spacer()
            // 닉네임 수정
            if userType == .user {
                NavigationLink(value: Route.ChangeUserName) {
                    Text("닉네임 수정")
                        .font(.regular14)
                        .foregroundStyle(.gray01)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

// MARK: - UserProfileView 의 이미지 프로필에서 사용하는 KFImage
private struct UserProfileKFImage: View {
    let url: URL
    let userType: UserType
    let selectedImage: UIImage
    
    var body: some View {
        KFImage.url(url)
            .placeholder {
                if userType == .user {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                        .frame(width: 70, height: 70)
                }
            }
            .loadDiskFileSynchronously(true) // 디스크에서 동기적으로 이미지 가져오기
            .cancelOnDisappear(true) // 화면 이동 시, 진행중인 다운로드 중단
            .cacheMemoryOnly() // 메모리 캐시만 사용 (디스크 X)
            .fade(duration: 0.2) // 이미지 부드럽게 띄우기
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipShape(Circle())
            .frame(width: 70, height: 70)
    }
}
