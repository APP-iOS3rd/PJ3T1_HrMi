//
//  AppViewModel.swift
//  JUDA
//
//  Created by phang on 2/5/24.
//

import SwiftUI
import FirebaseMessaging

// MARK: - 앱 전체에서 사용
@MainActor
final class AppViewModel: ObservableObject {
    // 탭바 상태
    @Published var tabBarState: Visibility = .visible
    @Published var selectedTabIndex: Int = 0
    @Published var locationManager = LocationManager()
	
	private let firebaseAuthService = FirebaseAuthService()
	
	func setUserNotificationOption() {
		let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound] // 필요한 알림 권한을 설정
		UNUserNotificationCenter.current().requestAuthorization(
			options: authOptions,
			completionHandler: { _, _ in }
		)
	}
	
	func setUserToken(uid: String, currentUserToken: String) async {
		do {
			let deviceToken = try await getDeviceToken()
			
			if currentUserToken != deviceToken {
				await firebaseAuthService.updateUserFcmToken(uid: uid, fcmToken: deviceToken)
			}
		} catch {
			print("error :: setUserToken", error.localizedDescription)
		}
	}
	
	func getDeviceToken() async throws -> String {
		do {
			let token = try await Messaging.messaging().token()
			return token
		} catch {
			throw TokenRequest.getToken
		}
	}
}

// MARK: - 앱 전체에서 사용되는 탭 바 숨기는 View Modifier
struct TabBarHidden: ViewModifier {
    @EnvironmentObject private var appViewModel: AppViewModel

    func body(content: Content) -> some View {
        content
            .onAppear {
                appViewModel.tabBarState = .hidden
            }
            .toolbar(appViewModel.tabBarState, for: .tabBar)
    }
}
