//
//  TermsAndVerificationView.swift
//  JUDA
//
//  Created by phang on 2/14/24.
//

import SwiftUI

// MARK: - 신규 회원: 개인 정보 활용 동의 체크 or 프로필 설정 화면
struct TermsAndVerificationView: View {
    @State private var viewType: TermsOrVerification = .TermsOfService
    // 알림 동의
    @State private var notificationAllowed: Bool = false
    
    var body: some View {
        switch viewType {
        case .TermsOfService:
            UserAgreementView(viewType: $viewType,
                              notificationAllowed: $notificationAllowed)
        case .ProfileSetting:
            ProfileSettingView(viewType: $viewType,
                               notificationAllowed: $notificationAllowed)
        }
    }
}
