//
//  AlarmStoreListCell.swift
//  JUDA
//
//  Created by phang on 1/31/24.
//

import SwiftUI
import Kingfisher

// MARK: - 알람 리스트 셀
struct AlarmStoreListCell: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    let alarm: UserNotification
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                // 게사물 좋아요 알람 내용
                Group {
                    Text(alarm.notificationField.likedUser.userName)
                        .font(.medium14)
                    +
                    Text(" 님이 게시물에 하트를 남겼어요.")
                        .font(.regular14)
                }
                .multilineTextAlignment(.leading)
                .foregroundStyle(.mainBlack)
                .overlay(alignment: .topLeading) {
                    NavigationLink(value: Route.NavigationProfile(userID: alarm.notificationField.likedUser.userID,
                                                                  usedTo: .myPage)) {
                        Text(alarm.notificationField.likedUser.userName)
                            .font(.medium14)
                            .foregroundStyle(.mainBlack)
                    }
                    .buttonStyle(EmptyActionStyle())
                }
                // 알람 왔던 시기
                Text(Formatter.formattedDateBeforeStyle(pastDate: alarm.notificationField.likedTime))
                    .font(.regular12)
                    .foregroundStyle(.gray01)
            }
            Spacer()
            // 해당 술상 이미지
            if let imageURL = alarm.notificationField.thumbnailImageURL {
                KFImage.url(imageURL)
                    .placeholder {
                        CircularLoaderView(size: 20)
                            .frame(maxWidth: 60, maxHeight: 60)
                            .clipShape(.rect(cornerRadius: 5))
                    }
                    .loadDiskFileSynchronously(true) // 디스크에서 동기적으로 이미지 가져오기
                    .cancelOnDisappear(true) // 화면 이동 시, 진행중인 다운로드 중단
                    .cacheMemoryOnly() // 메모리 캐시만 사용 (디스크 X)
                    .fade(duration: 0.2) // 이미지 부드럽게 띄우기
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 60, maxHeight: 60)
                    .clipShape(.rect(cornerRadius: 5))
            } else {
                Image("defaultprofileimage")
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fill)
                    .frame(maxWidth: 60, maxHeight: 60)
                    .clipShape(.rect(cornerRadius: 5))
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: 80, alignment: .leading)
        .padding(.horizontal, 20)
    }
}
