//
//  PostPhotoScroll.swift
//  JUDA
//
//  Created by Minjae Kim on 1/29/24.
//

import SwiftUI
import Kingfisher

// MARK: - 술상 디테일에서 사진 스크롤뷰
struct PostPhotoScroll: View {
    @State private var selectedIndex = 0
    @State private var isFullSizePhotoPresented = false
	@State private var windowWidth: CGFloat = 0
	let postPhotosURL: [URL]
	
    var body: some View {
		// 사진 페이징 스크롤 형식
		TabView(selection: $selectedIndex) {
			if !postPhotosURL.isEmpty {
                ForEach(0..<postPhotosURL.count, id: \.self) { index in
					KFImage.url(postPhotosURL[index])
						.placeholder {
							CircularLoaderView(size: 20)
								.frame(width: 70, height: 103.48)
						}
						.loadDiskFileSynchronously(true) // 디스크에서 동기적으로 이미지 가져오기
						.cancelOnDisappear(true) // 화면 이동 시, 진행중인 다운로드 중단
						.cacheMemoryOnly() // 메모리 캐시만 사용 (디스크 X)
						.fade(duration: 0.2) // 이미지 부드럽게 띄우기
						.resizable()
						.aspectRatio(contentMode: .fill)
						.frame(width: windowWidth)// clipped() 문제로 frame 값 지정
						.clipped()
						.onTapGesture {
							isFullSizePhotoPresented = true
						}
				}
			} else {
				Text("No Image")
					.font(.medium16)
					.foregroundStyle(.mainBlack)
					.frame(maxWidth: .infinity, maxHeight: .infinity)
			}
		}
		.frame(height: 350)
		.padding(.bottom, 10)
		.tabViewStyle(.page)
		// 사진을 탭했을 시, 전체화면에서 사진의 원본 비율로 보여주는 뷰
		.fullScreenCover(isPresented: $isFullSizePhotoPresented) {
			ZStack(alignment: .topTrailing) {
				Color.black
				// 사진 넘겨서 보는 탭뷰
				TabView(selection: $selectedIndex) {
					ForEach(0..<postPhotosURL.count, id: \.self) { index in
						KFImage.url(postPhotosURL[index])
							.placeholder {
								CircularLoaderView(size: 20)
									.frame(width: 70, height: 103.48)
							}
							.loadDiskFileSynchronously(true) // 디스크에서 동기적으로 이미지 가져오기
							.cancelOnDisappear(true) // 화면 이동 시, 진행중인 다운로드 중단
							.cacheMemoryOnly() // 메모리 캐시만 사용 (디스크 X)
							.fade(duration: 0.2) // 이미지 부드럽게 띄우기
							.resizable()
							.aspectRatio(contentMode: .fit)
					}
				}
				.tabViewStyle(.page)
				// 사진 크게보기 닫기 버튼
				Button {
					// 해당 뷰 내려줌
					isFullSizePhotoPresented = false
				} label: {
					Image(systemName: "xmark")
						.foregroundStyle(.gray01)
						.font(.bold20)
						.padding(.top, 30)
				}
				.padding(30)
			}
			.ignoresSafeArea()
		}
		.task {
			windowWidth = TagHandler.getScreenWidthWithoutPadding(padding: 0)
		}
    }
}
