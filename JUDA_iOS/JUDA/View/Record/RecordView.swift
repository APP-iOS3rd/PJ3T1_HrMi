//
//  RecordView.swift
//  JUDA
//
//  Created by 정인선 on 1/29/24.
//

import SwiftUI

// MARK: - 술상 기록 화면
struct RecordView: View {
    // Navigation을 위한 환경 프로퍼티
    @EnvironmentObject private var navigationRouter: NavigationRouter
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var recordViewModel: RecordViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel
    @EnvironmentObject private var postViewModel: PostViewModel
	
    // 기록 타입 ( 작성 or 수정 )
    let recordType: RecordType
    // TextEditor focus 상태 프로퍼티
    @FocusState private var isFocusedTextEditor: Bool
    // TextField focus 상태 프로퍼티
    @FocusState private var isFocusedTextField: Bool
    // VStack에 id 값을 부여하기 위한 네임스페이스
    @Namespace private var textField
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                // MARK: iOS 16.4 이상
                if #available(iOS 16.4, *) {
                    ScrollView {
                        RecordContent(recordType: recordType, isFocusedTextEditor: $isFocusedTextEditor,
                                      isFocusedTextField: $isFocusedTextField,
                                      textField: textField, proxy: proxy)
                    }
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                    // 스크롤 했을 때, 키보드 사라지기
                    .scrollDismissesKeyboard(.immediately)
                    // 탭했을 때, focus 상태 변경
                    .onTapGesture {
                        if isFocusedTextEditor {
                            isFocusedTextEditor = false
                        }
                        if isFocusedTextField {
                            isFocusedTextField = false
                        }
                    }
                } else {
                    ScrollView {
                        RecordContent(recordType: recordType, isFocusedTextEditor: $isFocusedTextEditor,
                                      isFocusedTextField: $isFocusedTextField,
                                      textField: textField, proxy: proxy)
                    }
                    // 스크롤 했을 때, 키보드 사라지기
                    .scrollDismissesKeyboard(.immediately)
                    // 탭했을 때, focus 상태 변경
                    .onTapGesture {
                        if isFocusedTextEditor {
                            isFocusedTextEditor = false
                        }
                        if isFocusedTextField {
                            isFocusedTextField = false
                        }
                    }
                }
            }
        }
        // post upload 여부에 따라 loadingView 표시
        .loadingView($recordViewModel.isPostUploading)
        .onAppear {
            // 글 내용 유무 체크
            recordViewModel.checkPostContentIsEmpty()
            // recordType에 따라 recordView에 값 띄워주기
            switch recordType {
            case .add:
                break
            case .edit:
                // recordViewModel에 해당 post의 content, foodTags 정보 넣어주기
                guard let post = recordViewModel.post else { return }
                recordViewModel.content = post.postField.content
                recordViewModel.foodTags = post.postField.foodTags
            }
        }
        // 글 내용 유무 체크
        .onChange(of: recordViewModel.content) { _ in
            recordViewModel.checkPostContentIsEmpty()
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigationRouter.back()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .foregroundStyle(.mainBlack)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if isFocusedTextEditor {
                        isFocusedTextEditor = false
                    }
                    if isFocusedTextField {
                        isFocusedTextField = false
                    }
                    DispatchQueue.main.async {
                        Task {
                            guard let user = authViewModel.currentUser else { return }
                            switch recordType {
                            case .add:
                                // post images upload, post upload
                                await recordViewModel.uploadPost(user: user)
                                // Post refetch
                                await postViewModel.fetchFirstPost()
                                // TODO: User posts ReFetch - cloud Fuction 업데이트 시점에 따라 코드 위치 변경
                                
                                // 업로드 후, recordViewModel Data clear
                                navigationRouter.clear()
                                
                            case .edit:
                                // post update
                                await recordViewModel.updatePost()
                                // Post refetch
                                await postViewModel.fetchFirstPost()
                                // TODO: User posts ReFetch - cloud Fuction 업데이트 시점에 따라 코드 위치 변경

                                // 업로드 후, recordViewModel Data clear
                                navigationRouter.clear()
                                
                            }
                        }
                    }
                } label: {
                    Text("완료")
                        .font(.regular16)
                }
                .foregroundStyle(recordViewModel.postContentIsEmpty ? .gray01 : .mainBlack)
                .disabled(recordViewModel.postContentIsEmpty)
            }
        }
    }
}

// MARK: - 술상 기록 화면에 보여줄 내용
struct RecordContent: View {
    @EnvironmentObject private var recordViewModel: RecordViewModel
    // post add/edit
    let recordType: RecordType
    // TextEditor focus 상태 프로퍼티
    var isFocusedTextEditor: FocusState<Bool>.Binding
    // TextField focus 상태 프로퍼티
    var isFocusedTextField: FocusState<Bool>.Binding
    // VStack에 id 값을 부여하기 위한 네임스페이스
    var textField: Namespace.ID
    // TextEditor에서 사용되는 placeholder
    private let placeholder = """
                             사진에 대해 설명해주세요.
                             음식과 함께 마신 술은 어땠나요?
                             """
    let proxy: ScrollViewProxy
    
    var body: some View {
        LazyVStack {
            // 선택된 사진들을 보여주는 가로 Scroll View
            SelectedPhotoHorizontalScroll(recordType: recordType)
            // 글 작성 TextEditor
            TextEditor(text: $recordViewModel.content)
            // TextEditor에 Text를 오버레이하여 placeholder로 보여줌
                .overlay(alignment: .topLeading) {
                    // content가 입력됐을 때, placeholder "" 처리
                    Text(recordViewModel.content.isEmpty ? placeholder : "")
                        .font(.regular16)
                        .padding(.leading, 6)
                        .padding(.top, 10)
                        .foregroundStyle(.gray01)
                        .onTapGesture {
                            // 오버레이 된 Text를 탭할 시, TextEditor focus 상태 변경
                            isFocusedTextEditor.wrappedValue = true
                        }
                }
                .font(.regular16)
                .frame(height: 300)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .focused(isFocusedTextEditor)
                .textInputAutocapitalization(.never) // 자동 대문자 설정 기능 비활성화
                .autocorrectionDisabled() // 자동 수정 비활성화
            //
            CustomDivider()
                .padding(.vertical, 10)
            // 음식 태그
            VStack {
                HStack(alignment: .lastTextBaseline) {
                    Text("음식 태그")
                        .font(.semibold18)
                    Text("(최대 10개)")
                        .font(.medium14)
                        .foregroundStyle(.gray01)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 5)
                // 음식 태그 추가 TextField
                FoodTagAddTextField(textField: textField, isFocusedTextField: isFocusedTextField, proxy: proxy)
                // 추가된 음식 태그를 보여주는 하단부
                FoodTagVertical()
            }
            .padding(.bottom, 5)
            // ScrollView focusing을 위한 VStack에 id 부여
            .id(textField)
        }
    }
}

//#Preview {
//    RecordView(recordType: RecordType.add)
//}

