//
//  AuthViewModel.swift
//  JUDA
//
//  Created by phang on 3/4/24.
//

import SwiftUI
import PhotosUI

import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn
import CryptoKit
import AuthenticationServices

// MARK: - Auth ( 로그인 / 로그아웃 / 탈퇴 / 본인 계정 )
@MainActor
final class AuthViewModel: ObservableObject {
    // 로그인 유무
    @AppStorage("signInStatus") var signInStatus: Bool = false
    // 신규 유저 or 기존 유저
    @Published var isNewUser: Bool = false
    // 현재 유저
    @Published var currentUser: User?
    // 로딩 중
    @Published var isLoading: Bool = false
    // Error
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    // Nonce : 암호와된 임의의 난수
    private var currentNonce: String?
    // Firebase Auth Service
    private let firebaseAuthService = FirebaseAuthService()
    // Firebase User Service
    private let firebaseUserService = FirebaseUserService()
    // Firebase Post Service
    private let firestorePostService = FirestorePostService()
    // Firebase Drink Service
    private let firestoreDrinkService = FirestoreDrinkService()
    // FireStorage Service
    private let fireStorageService = FireStorageService()
    // Firestore - db 연결
    private let db = Firestore.firestore()
    private let postCollection = "posts"
    private let drinkCollection = "drinks"
    
    // 현재 유저 있는지 확인, uid 받기
    private func checkCurrentUserID()  throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("error :: currentUser 없음")
            defer {
                Task {
                    await signOut()
                }
            }
            throw AuthManagerError.noUserID
        }
        return uid
    }
    
    // provider 받아오기 ( AuthProviderOption - rawValue )
    private func getProviderOptionString() throws -> String {
        guard let providerData = Auth.auth().currentUser?.providerData else {
            throw AuthManagerError.noProviderData
        }
        var providers: [String] = []
        for provider in providerData {
            providers.append(provider.providerID)
        }
        guard let authProviderOptionString = providers.first else {
            throw AuthManagerError.noProviderData
        }
        return authProviderOptionString
    }
    
    // 데이터 초기화
    func resetData() {
        signInStatus = false
        currentUser = nil
        isLoading = false
        isNewUser = false
    }
    
    // 실시간 업데이트 리스너 등록
    func startListeningForUserField() async {
        do {
            let uid = try checkCurrentUserID()
            firebaseAuthService.startListeningForUser(uid: uid) { user in
                if let user = user {
                    self.currentUser?.userField = user
                }
            }
        } catch {
            print("error :: startListeningForUserField :", error.localizedDescription)
        }
    }
    
    // MyPage / Setting 에서 사용
    // '알림 설정' 탭했을 때, 시스템 설정 받아와서 파베에 업데이트
    func getSystemAlarmSetting() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return try await updateUserNotificationAllowed(systemSetting: settings.alertSetting)
    }
    
    // MyPage / Setting 에서 사용
    // '알림 설정' - 시스템 설정으로 이동하는 메서드
    func openAppSettings(notUsed: Bool) {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
    
    // MyPage / Setting 에서 사용
    // 유저 닉네임 수정 시, 2글자 이상 10글자 이하 && 기존 닉네임과 같은지 체크
    func isChangeUserName(changeName: String) -> Bool {
        guard let user = currentUser else {
            return false
        }
        return changeName.count >= 2 && changeName.count <= 10 && user.userField.name != changeName
    }
    
    // 유저 프로필 사진 변경 시, 사용되는 메서드
    func updateImage(selectedPhotos: [PhotosPickerItem]) async throws -> UIImage {
        guard let selectedPhoto = selectedPhotos.first else {
            throw PhotosPickerImageLoadingError.noSelectedPhotos
        }
        if let data = try await selectedPhoto.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            return uiImage
        } else {
            throw PhotosPickerImageLoadingError.invalidImageData
        }
    }
    
    // 회원 가입 - ProfileSettingView 에서 모든 항목을 입력하고, '완료' 를 눌렀을 때 수행
    func signInDoneButtonTapped(name: String, age: Int, profileImage: UIImage?, gender: String, notification: Bool) async {
        let provider: String? = Auth.auth().currentUser?.providerData.first?.providerID
        do {
            // 애플의 경우 로그아웃이 된 상태라, 애플인 것을 google 이 아닌 경우로 체크
            if provider != AuthProviderOption.google.rawValue {
                // 재로그인
                let signWithApple = SignInWithAppleHelper()
                let appleIDCredential = try await signWithApple()
                isLoading = true
                await signInApple(appleIDCredential: appleIDCredential)
                signInStatus = true
            }
            // 프로필 이미지 storage 저장
            let url = await uploadProfileImageToStorage(image: profileImage)
            // 유저 이름, 생일, 성별, 프로필, 알림 동의 등 forestore 에 저장
            await addUserDataToStore(
                name: name,
                age: age,
                profileImageURL: url,
                gender: gender,
                notification: notification
            )
            // 유저 데이터 받기
            await getCurrentUser()
        } catch {
            errorMessage = "회원가입에 문제가 발생했어요.\n다시 시도해주세요."
            showError = true
            print("error :: signInDoneButtonTapped", error.localizedDescription)
        }
    }
    
    // 회원 탈퇴 - authProviders 를 체크해서 apple or google 탈퇴 로직 수행
    func deleteAccount() async -> Bool {
        isLoading = true
        guard let authProvider = currentUser?.userField.authProviders else {
            isLoading = false
            return false
        }
        var result: Bool
        // 애플 유저일때, 탈퇴 로직
        if authProvider == AuthProviderOption.apple.rawValue {
            result = await deleteAppleAccount()
        // 구글 유저일때, 탈퇴 로직
        } else if authProvider == AuthProviderOption.google.rawValue {
            result = await deleteGoogleAccount()
        // ?? - 예외
        } else {
            result = false
        }
        isLoading = false
        return result
    }
}

// MARK: - User Fetch
extension AuthViewModel {
    // 데이터를 한번에 병렬로 받아오기 위해 사용하는 enum
    private enum CurrentUserResult {
        case userField(UserField?)
        case posts([Post]?)
        case likedPosts([Post]?)
        case likedDrinks([Drink]?)
        case notifications([UserNotification]?)
    }
    
    // 현재 CurrentUser : User 가져오기
    func getCurrentUser() async {
        var userFieldResult: UserField?
        var postsResult: [Post]?
        var likedPostsResult: [Post]?
        var likedDrinksResult: [Drink]?
        var notificationsResult: [UserNotification]?
        do {
            let uid = try checkCurrentUserID()
            await withTaskGroup(of: CurrentUserResult.self) { taskGroup in
                // 현재 유저 UserField 받아오기
                taskGroup.addTask { .userField(await self.getCurrentUserField(uid: uid)) }
                // 현재 유저 Posts 받아오기
                taskGroup.addTask { .posts(await self.getCurrentUserPosts(uid: uid)) }
                // 현재 유저 LikedPosts 받아오기
                taskGroup.addTask { .likedPosts(await self.getCurrentUserLikedPosts(uid: uid)) }
                // 현재 유저 LikedDrinks 받아오기
                taskGroup.addTask { .likedDrinks(await self.getCurrentUserLikedDrinks(uid: uid)) }
                // 현재 유저 Notifications 받아오기
                taskGroup.addTask { .notifications(await self.getCurrentUserNotifications(uid: uid)) }
                // taskGroup 종료 시, result 받아서 메서드 내부의 프로퍼티에 할당
                for await result in taskGroup {
                    switch result {
                    case .userField(let userField):
                        userFieldResult = userField
                    case .posts(let posts):
                        postsResult = posts
                    case .likedPosts(let likedPosts):
                        likedPostsResult = likedPosts
                    case .likedDrinks(let likedDrinks):
                        likedDrinksResult = likedDrinks
                    case .notifications(let notifications):
                        notificationsResult = notifications
                    }
                }
                // 옵셔널 해제
                guard let userField = userFieldResult,
                      let posts = postsResult,
                      let likedPosts = likedPostsResult,
                      let likedDrinks = likedDrinksResult,
                      let notifications = notificationsResult else { return }
                // 유저에 데이터 값 할당
                currentUser = User(userField: userField,
                                   posts: posts,
                                   likedPosts: likedPosts,
                                   likedDrinks: likedDrinks,
                                   notifications: notifications)
            }
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            print("error :: getCurrentUser", error.localizedDescription)
        }
    }
    
    // 현재 유저 UserField 받아오기
    private func getCurrentUserField(uid: String) async -> UserField? {
        do {
            let userField = try await firebaseUserService.fetchUserFieldData(uid: uid)
            return userField
        } catch {
            errorMessage = error.localizedDescription
            print("error :: getCurrentUserField", error.localizedDescription)
            return nil
        }
    }
    
    // 현재 유저 Posts 받아오기
    func getCurrentUserPosts(uid: String) async -> [Post]? {
        do {
            let posts = try await firebaseUserService.fetchUserWrittenPosts(uid: uid)
            return posts
        } catch {
            errorMessage = error.localizedDescription
            print("error :: getCurrentUserPosts", error.localizedDescription)
            return nil
        }
    }
    
    // 현재 유저 LikedPosts 받아오기
    private func getCurrentUserLikedPosts(uid: String) async -> [Post]? {
        do {
            let likedPosts = try await firebaseUserService.fetchUserLikedPosts(uid: uid)
            return likedPosts
        } catch {
            errorMessage = error.localizedDescription
            print("error :: getCurrentUserLikedPosts", error.localizedDescription)
            return nil
        }
    }
    
    // 현재 유저 LikedDrinks 받아오기
    private func getCurrentUserLikedDrinks(uid: String) async -> [Drink]? {
        do {
            let likedDrinks = try await firebaseUserService.fetchUserLikedDrink(uid: uid)
            return likedDrinks
        } catch {
            errorMessage = error.localizedDescription
            print("error :: getCurrentUserLikedDrinks", error.localizedDescription)
            return nil
        }
    }
    
    // 현재 유저 Notifications 받아오기
    private func getCurrentUserNotifications(uid: String) async -> [UserNotification]? {
        do {
            let notifications = try await firebaseUserService.fetchUserNotifications(uid: uid)
            return notifications
        } catch {
            errorMessage = error.localizedDescription
            print("error :: getCurrentUserNotifications", error.localizedDescription)
            return nil
        }
    }
}

// MARK: - User Update
extension AuthViewModel {
    // 유저가 좋아하는 술 리스트에 추가 or 삭제
    func updateLikedDrinks(isLiked: Bool, selectedDrink: Drink) async {
        // isLiked 가 먼저 수정이 되고 메서드가 실행이 됨
        if !isLiked { // 좋아요 X -> O
            currentUser?.likedDrinks.removeAll { $0.drinkField.drinkID == selectedDrink.drinkField.drinkID }
            await deleteUserLikedList(type: .drinks, id: selectedDrink.drinkField.drinkID)
        } else { // 좋아요 O -> X
            if let user = currentUser,
               !user.likedDrinks.contains(where: { $0.drinkField.drinkID == selectedDrink.drinkField.drinkID }) {
                currentUser?.likedDrinks.append(selectedDrink)
                await addUserLikedList(type: .drinks, id: selectedDrink.drinkField.drinkID)
            }
        }
    }
    
    // 유저가 좋아하는 게시글 (술상) 리스트에 추가 or 삭제
    func updateLikedPosts(isLiked: Bool, selectedPost: Post) async {
        // isLiked 가 먼저 수정이 되고 메서드가 실행이 됨
        if !isLiked { // 좋아요 X -> O
            currentUser?.likedPosts.removeAll { $0.postField.postID == selectedPost.postField.postID }
            await deleteUserLikedList(type: .posts, id: selectedPost.postField.postID)
        } else { // 좋아요 O -> X
            if let user = currentUser,
               !user.likedPosts.contains(where: { $0.postField.postID == selectedPost.postField.postID }) {
                currentUser?.likedPosts.append(selectedPost)
                await addUserLikedList(type: .posts, id: selectedPost.postField.postID)
            }
        }
    }
    
    // 유저 정보 업데이트 - [ LikedPosts / LikedDrinks ] in [ Posts / Drinks ]
    private func deleteUserLikedList(type: UserLikedListType, id: String?) async {
        do {
            guard let id = id else { return }
            let uid = try checkCurrentUserID()
            let likedUsersIDCollection = "likedUsersID"
            switch type {
            case .posts:
                let documentRef = db.collection(postCollection).document(id)
                    .collection(likedUsersIDCollection).document(uid)
                try await firestorePostService.deletePostDocument(document: documentRef)
            case .drinks:
                let documentRef = db.collection(drinkCollection).document(id)
                    .collection(likedUsersIDCollection).document(uid)
                try await firestoreDrinkService.deleteDrinkDocument(document: documentRef)
            }
        } catch {
            print("error :: deleteUserLikedList / \(type) :", error.localizedDescription)
        }
    }

    // 유저 정보 업데이트 - [ LikedPosts / LikedDrinks ] in [ Posts / Drinks ]
    private func addUserLikedList(type: UserLikedListType, id: String?) async {
        do {
            guard let id = id else { return }
            let uid = try checkCurrentUserID()
            let likedUsersIDCollection = "likedUsersID"
            switch type {
            case .posts:
                let collectionRef = db.collection(postCollection).document(id)
                    .collection(likedUsersIDCollection)
                await firestorePostService.uploadPostLikedUsersID(collection: collectionRef, uid: uid)
            case .drinks:
                let collectionRef = db.collection(drinkCollection).document(id)
                    .collection(likedUsersIDCollection)
                await firestoreDrinkService.uploadDrinkLikedUsersID(collection: collectionRef, uid: uid)
            }
        } catch {
            print("error :: addUserLikedList / \(type) :", error.localizedDescription)
        }
    }
    
    // 닉네임 수정
    func updateUserName(userName: String) async {
        do {
            let uid = try checkCurrentUserID()
            await firebaseAuthService.updateUserName(uid: uid, userName: userName)
        } catch {
            showError = true
            errorMessage = "닉네임 변경에 문제가 발생했어요.\n다시 시도해주세요."
        }
    }
    
    // 유저 프로필 url 수정 ( url 이 없었는데, 생기는 경우 )
    func updateUserProfileImageURL(url: URL?) async {
        do {
            guard let url = url else { return }
            let uid = try checkCurrentUserID()
            await firebaseAuthService.updateUserProfileImageURL(uid: uid, url: url)
        } catch {
            print("error :: updateUserProfileImageURL", error.localizedDescription)
        }
    }
    
    // 유저 '알림 설정' 수정
    private func updateUserNotificationAllowed(systemSetting: UNNotificationSetting) async throws -> Bool {
        guard let user = currentUser else {
            throw AuthManagerError.noUser
        }
        switch systemSetting {
            // 허용한 상태일 경우
            case .enabled:
                // 파베 유저 데이터의 알림 허용 상태 X 경우, 파베에 허용 O 로 업데이트
                if !user.userField.notificationAllowed {
                    await firebaseAuthService.updateUserNotification(uid: user.userField.userID!, notificationAllowed: true)
                }
                return true
            // 허용하지 않은 상태 + 나머지 모든 경우
            default:
                // 파베 유저 데이터의 알림 허용 상태 O 경우, 파베에 허용 X 로 업데이트
                if user.userField.notificationAllowed {
                    await firebaseAuthService.updateUserNotification(uid: user.userField.userID!, notificationAllowed: false)
                }
                return false
        }
    }
}

// MARK: - Upload / 데이터 저장
extension AuthViewModel {
    // 유저 정보 저장
    func addUserDataToStore(name: String, age: Int, profileImageURL: URL?,
                            gender: String, notification: Bool) async {
        do {
            let uid = try checkCurrentUserID()
            firebaseAuthService.addUserDataToStore(
                userData: UserField(
                    name: name, age: age, gender: gender,
					fcmToken: "", notificationAllowed: notification,
                    profileImageURL: profileImageURL ?? URL(string: ""),
                    authProviders: try getProviderOptionString()),
                uid: uid)
        } catch {
            print("error :: addUserDataToStore", error.localizedDescription)
        }
    }
    
    // 유저 가입 시, 프로필 이미지 올리기 + 이미지 URL 저장
    func uploadProfileImageToStorage(image: UIImage?) async  -> URL? {
        do {
            guard let image = image else {
                return nil
            }
            let uid = try checkCurrentUserID()
            try await fireStorageService.uploadImageToStorage(folder: .user,
                                                              image: image,
                                                              fileName: uid)
            // 유저 프로필 받아오기
            let url = try await fireStorageService.fetchImageURL(folder: .user,
                                                                 fileName: uid)
            //
            currentUser?.userField.profileImageURL = url
            return url
        } catch {
            print("error :: uploadProfileImageToStorage", error.localizedDescription)
            return nil
        }
    }
}

// MARK: - 로그아웃 ( Apple & Google 공통 )
extension AuthViewModel {
    // 로그아웃
    func signOut() async {
        do {
            try Auth.auth().signOut()
            resetData()
        } catch {
            errorMessage = "로그아웃에 문제가 발생했어요.\n다시 시도해주세요."
            showError = true
        }
    }
}

// MARK: - 로그인 / 회원 탈퇴 ( Apple )
extension AuthViewModel {
    // 로그인 request
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let signInWithAppleHelper = SignInWithAppleHelper()
        request.requestedScopes = [.fullName, .email]
        let nonce = signInWithAppleHelper.randomNonceString()
        currentNonce = nonce
        request.nonce = signInWithAppleHelper.sha256(nonce)
    }
    
    // 로그인 completion
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                print("error :: appleIDCredential")
                return
            }
            let fullName = appleIDCredential.fullName
            currentUser?.userField.name = (fullName?.familyName ?? "") + (fullName?.givenName ?? "")
            Task {
                // 로그인 중 -
                isLoading = true
                // 로그인
                await signInApple(appleIDCredential: appleIDCredential)
                //
                let uid = try checkCurrentUserID()
                // 신규 유저 체크
                isNewUser = await firebaseAuthService.isNewUser(uid: uid)
                // 신규 유저
                if isNewUser {
                    await signOut()
                    self.isNewUser = true
                    print("First ✨ - Apple Sign Up 🍎")
                } else {
                    print("Apple Sign In 🍎")
                    await getCurrentUser()
                    self.signInStatus = true
                }
            }
        case .failure(_):
            resetData()
            errorMessage = "로그인에 문제가 발생했어요.\n다시 시도해주세요."
            showError = true
        }
    }
    
    // 로그인
    func signInApple(appleIDCredential: ASAuthorizationAppleIDCredential) async {
        await firebaseAuthService.signInApple(appleIDCredential: appleIDCredential,
                                                currentNonce: currentNonce)
    }
    
    // 회원가입 or 회원탈퇴 시, 재 로그인 - Apple
    private func reauthApple() async -> ASAuthorizationAppleIDCredential? {
        do {
            let signInWithAppleHelper = SignInWithAppleHelper()
            let appleIDCredential = try await signInWithAppleHelper()
            return appleIDCredential
        } catch {
            errorMessage = "작업에 문제가 발생했어요.\n다시 시도해주세요."
            showError = true
            return nil
        }
    }
    
    // 회원탈퇴 - Apple
    private func deleteAppleAccount() async -> Bool {
        do {
            guard try getProviderOptionString() == AuthProviderOption.apple.rawValue else { return false }
            let uid = try checkCurrentUserID()
            try await firebaseAuthService.deleteAccountWithApple()
			firebaseAuthService.deleteUserData(uid: uid)
            resetData()
            return true
        } catch {
            print("error :: deleteAppleAccount", error.localizedDescription)
            errorMessage = "회원탈퇴에 문제가 발생했어요.\n다시 시도해주세요."
            return false
        }
    }
}

// MARK: - 로그인 / 회원 탈퇴 ( Google )
extension AuthViewModel {
    // 로그인
    func signInWithGoogle() async {
        do {
            let signInWithGoogleHelper = SignInWithGoogleHelper()
            let token = try await signInWithGoogleHelper.signIn()
            // Firebase auth
            let credential = GoogleAuthProvider.credential(
                withIDToken: token.idToken,
                accessToken: token.accessToken
            )
            // 로그인 중 -
            isLoading = true
            // sign in
            try await Auth.auth().signIn(with: credential)
            //
            let uid = try checkCurrentUserID()
            // 신규 유저 체크
            isNewUser = await firebaseAuthService.isNewUser(uid: uid)
            // 신규 유저
            if isNewUser {
                self.isNewUser = true
                print("First ✨ - Google Sign Up 🤖")
            } else {
                print("Google Sign In 🤖")
                await getCurrentUser()
                self.signInStatus = true
            }
        } catch {
            print("error :: signInWithGoogle", error.localizedDescription)
            errorMessage = "로그인에 문제가 발생했어요.\n다시 시도해주세요."
            showError = true
            resetData()
        }
    }
    
    // 회원탈퇴 - Google
    private func deleteGoogleAccount() async -> Bool {
        do {
            guard try getProviderOptionString() == AuthProviderOption.google.rawValue else { return false }
            let uid = try checkCurrentUserID()
            try await firebaseAuthService.deleteAccountWithGoogle()
            firebaseAuthService.deleteUserData(uid: uid)
            resetData()
            return true
        } catch {
            print("error :: deleteGoogleAccount", error.localizedDescription)
            errorMessage = "회원탈퇴에 문제가 발생했어요.\n다시 시도해주세요."
            return false
        }
    }
}
