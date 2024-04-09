//
//  FirebaseAuthService.swift
//  JUDA
//
//  Created by phang on 3/4/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseFunctions
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices

// MARK: - Firebase : Auth
@MainActor
final class FirebaseAuthService {
    // Firestore - db 연결
    private let db = Firestore.firestore()
    private let userCollection = "users"
    // 실시간 반영을 위한 리스너
    private var listener: ListenerRegistration?
	// Cloud Function 연결
	lazy var functions = Functions.functions()
    
    // firestore 에 유저 존재 유무 체크
    func isNewUser(uid: String) async -> Bool {
        do {
            let document = try await db.collection(userCollection).document(uid).getDocument()
            return !document.exists
        } catch {
            print("error :: isNewUser", error.localizedDescription)
            return true
        }
    }
}

// MARK: - Upload / 저장
extension FirebaseAuthService {
    // firestore 에 유저 저장
    func addUserDataToStore(userData: UserField, uid: String) {
        do {
            try db.collection(userCollection).document(uid).setData(from: userData)
        } catch {
            print("error :: addUserDataToStore", error.localizedDescription)
        }
    }
}
    
// MARK: - Update
extension FirebaseAuthService {
    // firestore 에서 유저 이름 변경
    func updateUserName(uid: String, userName: String) async {
        do {
            let docRef = db.collection(userCollection).document(uid)
            try await docRef.updateData(["name": userName])
        } catch {
            print("error :: updateUserName", error.localizedDescription)
        }
    }
    
    // firestore 에서 유저 알림 상태 설정 변경
    func updateUserNotification(uid: String, notificationAllowed: Bool) async {
        do {
            let docRef = db.collection(userCollection).document(uid)
            try await docRef.updateData(["notificationAllowed": notificationAllowed])
        } catch {
            print("error :: updateUserNotification", error.localizedDescription)
        }
    }
	
	// firestore 에서 유저 fcm token 변경
	func updateUserFcmToken(uid: String, fcmToken: String) async {
		do {
			let docRef = db.collection(userCollection).document(uid)
			try await docRef.updateData(["fcmToken": fcmToken])
		} catch {
			print("error :: updateUserFcmToken", error.localizedDescription)
		}
	}
    
    // firestore 에서 유저 프로필 url 변경
    func updateUserProfileImageURL(uid: String, url: URL) async {
        do {
            let docRef = db.collection(userCollection).document(uid)
            try await docRef.updateData(["profileImageURL": url.absoluteString])
        } catch {
            print("error :: updateUserProfileImageURL", error.localizedDescription)
        }
    }
}

// MARK: - 데이터 실시간 업데이트
extension FirebaseAuthService {
    //
    func startListeningForUser(uid: String, 
                               completion: @escaping (UserField?) -> Void) {
        let userRef = db.collection(userCollection).document(uid)
        // 기존에 활성화된 리스너가 있다면 삭제
        listener?.remove()
        // 새로운 리스너 등록
        listener = userRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard self != nil else { return }
            if let error = error {
                print("error :: startListeningForUser", error.localizedDescription)
                completion(nil)
                return
            }
            if let documentSnapshot = documentSnapshot,
               let user = try? documentSnapshot.data(as: UserField.self) {
                completion(user)
            } else {
                completion(nil)
            }
        }
    }
}

// MARK: - 로그인 / 회원 탈퇴 ( Apple )
extension FirebaseAuthService {
    // 로그인
    func signInApple(appleIDCredential: ASAuthorizationAppleIDCredential,
                     currentNonce: String?) async {
        guard let nonce = currentNonce else {
            fatalError("Invalid state: a login callback was received, but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("Unable to fetdch identify token.")
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("Unable to serialise token string from data: \(appleIDToken.debugDescription)")
            return
        }
        let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                       rawNonce: nonce,
                                                       fullName: appleIDCredential.fullName)
        do {
            let _ = try await Auth.auth().signIn(with: credential)
        } catch {
            print("Error authenticating: \(error.localizedDescription)")
        }
    }
    
    // 회원탈퇴 - Apple
    func deleteAccountWithApple() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthManagerError.noUser
        }
        let signInWithAppleHelper = SignInWithAppleHelper()
        let appleIDCredential = try await signInWithAppleHelper()
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            print("ID 토큰 가져오지 못함")
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            print("데이터 -> 토큰 문자열 에러 : \(appleIDToken.debugDescription)")
            return
        }
        let nonce = signInWithAppleHelper.randomNonceString()
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
        try await user.reauthenticate(with: credential)
        // 애플에서도 앱에 대한 로그인 토큰 삭제
        guard let authorizationCode = appleIDCredential.authorizationCode else { return }
        guard let authCodeString = String(data: authorizationCode, encoding: .utf8) else { return }
        try await Auth.auth().revokeToken(withAuthorizationCode: authCodeString)
        // 삭제
        try await user.delete()
    }
}

// MARK: - 회원 탈퇴 ( Google )
extension FirebaseAuthService {
    // 회원탈퇴 - Google
    func deleteAccountWithGoogle() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthManagerError.noUser
        }
        let signInWithGoogleHelper = SignInWithGoogleHelper()
        let token = try await signInWithGoogleHelper.signIn()
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: token.idToken,
            accessToken: token.accessToken
        )
        try await user.reauthenticate(with: credential)
        // 구글에서도 앱에 대한 연결 삭제
        try await GIDSignIn.sharedInstance.disconnect()
        // 삭제
        try await user.delete()
    }
}

// MARK: - 회원 탈퇴 (Cloud Function)
extension FirebaseAuthService {
    func deleteUserData(uid: String) {
		print(uid)
        let reqData = ["userID": uid]
        functions.httpsCallable("onUserDelete").call(reqData) { _, error in
            if let error = error as NSError? {
                print("error :: deleteUserData", error.localizedDescription)
            }
        }
    }
}
