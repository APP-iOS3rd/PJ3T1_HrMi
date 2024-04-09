//
//  DrinkInfoView.swift
//  JUDA
//
//  Created by 홍세희 on 2024/01/24.
//

import SwiftUI

// MARK: - 술장 탭
struct DrinkInfoView: View {
    @StateObject private var navigationRouter = NavigationRouter()
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var drinkViewModel: DrinkViewModel

	@State private var isShowingSortSheet: Bool = false

    @State private var drinkSearchText = ""
    @State private var searchDrinks = [Drink]()
    @FocusState private var isFocused: Bool
    
	var body: some View {
        NavigationStack(path: $navigationRouter.path) {
            ZStack {
                VStack(spacing: 0) {
                    // 서치바
                    SearchBar(inputText: $drinkSearchText, isFocused: $isFocused) {
                        Task {
                            self.searchDrinks = await drinkViewModel.getSearchedDrinks(from: drinkSearchText)
                        }
                    }
                    // 서치바 Text가 없을 때, 술 검색 결과 비워주기
                    .onChange(of: drinkSearchText) { _ in
                        if drinkSearchText == "" {
                            self.searchDrinks = []
                        }
                    }
                    // MARK: 검색어 입력 중
                    if isFocused == true {
                        VStack {
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Text("술 이름을 검색해보세요.")
                                .font(.regular16)
                                .foregroundStyle(.gray01)
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    // MARK: 검색 중
                    } else if drinkViewModel.isSearching {
                        VStack {
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            CircularLoaderView(size: 40)
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    // MARK: 검색 완료 / 결과 X
                    } else if !drinkSearchText.isEmpty,
                              self.searchDrinks.isEmpty,
                              isFocused == false {
                        VStack {
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Text("검색된 술이 없어요.")
                                .font(.regular16)
                                .foregroundStyle(.gray01)
                            Rectangle()
                                .fill(.background)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    // MARK: 검색 완료 / 결과 O
                    } else if !drinkSearchText.isEmpty,
                              !self.searchDrinks.isEmpty,
                              isFocused == false {
                        // 검색 시, DrinkInfoList
                        DrinkInfoList(searchDrinks: searchDrinks, searchInDrinkInfo: true)
                    // MARK: 검색 X
                    } else {
                        ScrollViewReader { value in
                            Group {
                                // 술 종류 *(종류 추가 시, horizontal scrollview 로 감싸서 사용)
                                CustomTextSegment(segments: DrinkType.list.map { $0.rawValue },
                                                  selectedSegmentIndex: $drinkViewModel.selectedDrinkTypeIndex)
                                .padding(.bottom, 14)
                                .padding([.top, .horizontal], 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                // 세그먼트 + 필터링
                                DrinkInfoSegment(optionNameList: DrinkSortType.list.map { $0.rawValue },
                                                 selectedSortingOption: drinkViewModel.selectedSortedTypeString,
                                                 isShowingSheet: $isShowingSortSheet)
                                // 술 뷰 - DrinkSelectHorizontalScrollBar 의 선택에 따라 자연스럽게 페이징으로 화면 전환
                                TabView(selection: $drinkViewModel.selectedDrinkTypeIndex) {
                                    // 각 술 타입에 맞는 리스트를 grid 와 list 에 뿌려줘야 함
                                    ForEach(DrinkType.list.indices, id: \.self) { _ in
                                        ScrollViewReader { proxy in
                                            Group {
                                                // 그리드
                                                if drinkViewModel.selectedViewType == .gridStyle {
                                                    DrinkInfoGrid()
                                                    // 리스트
                                                } else {
                                                    DrinkInfoList()
                                                }
                                            }
                                            .onChange(of: drinkViewModel.selectedDrinkTypeIndex) { newValue in
                                                proxy.scrollTo(0, anchor: .center) // 술 종류 이동 시, 스크롤 상단 고정
                                            }
                                            .onChange(of: drinkViewModel.selectedSortedTypeString) { newValue in
                                                proxy.scrollTo(0, anchor: .center) // 술 정렬 변경 시, 스크롤 상단 고정
                                            }
                                        }
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .onChange(of: drinkViewModel.selectedDrinkTypeIndex) { newValue in
                                    withAnimation {
                                        // 선택 카테고리 변경 시, 데이터 받아오기
                                        drinkViewModel.selectedDrinkTypeIndex = newValue
                                        value.scrollTo(newValue, anchor: .center)
                                    }
                                    Task {
                                        // 술 데이터 받아오기
                                        await drinkViewModel.loadDrinksFirstPage()
                                    }
                                }
                                .animation(.spring, value: drinkViewModel.selectedDrinkTypeIndex)
                            }
                        }
                    }
                }
                // 키보드 내리기
                .onTapGesture {
                    isFocused = false
                }
                // 정렬 방식 선택 CustomBottomSheet (.drinkInfo)
                .sheet(isPresented: $isShowingSortSheet) {
                    CustomBottomSheetContent(optionNameList: DrinkSortType.list.map { $0.rawValue },
                                             isShowingSheet: $isShowingSortSheet,
                                             selectedSortingOption: $drinkViewModel.selectedSortedTypeString,
                                             bottomSheetTypeText: BottomSheetType.drinkInfo)
                        .presentationDetents([.drinkInfo])
                        .presentationDragIndicator(.hidden) // 시트 상단 인디케이터 비활성화
                        .interactiveDismissDisabled() // 내려서 닫기 비활성화
                }
                // 술 정렬 타입 변경 시, 데이터 받아오기
                .onChange(of: drinkViewModel.selectedSortedTypeString) { _ in
                    Task {
                        await drinkViewModel.loadDrinksFirstPage()
                    }
                }
            }
            .navigationDestination(for: Route.self) { value in
                switch value {
                case .ChangeUserName:
                    ChangeUserNameView()
                case .AddTag:
                    AddTagView()
                        .modifier(TabBarHidden())
                case .Login:
                    LogInView()
                        .modifier(TabBarHidden())
                case .NavigationPosts(let usedTo,
                                      let searchTagType,
                                      let taggedPosts,
                                      let selectedDrinkName,
                                      let selectedFoodTag):
                    NavigationPostsView(usedTo: usedTo,
                                        searchTagType: searchTagType,
                                        taggedPosts: taggedPosts,
                                        selectedDrinkName: selectedDrinkName,
                                        selectedFoodTag: selectedFoodTag)
                case .NavigationPostsTo(let usedTo,
                                        let searchTagType,
                                        let postSearchText):
                    NavigationPostsView(usedTo: usedTo,
                                        searchTagType: searchTagType,
                                        postSearchText: postSearchText)
                case .NavigationProfile(let userID,
                                        let usedTo):
                    NavigationProfileView(userID: userID,
                                          usedTo: usedTo)
                case .Record(let recordType):
                    RecordView(recordType: recordType)
                case .DrinkDetail(let drink):
                    DrinkDetailView(drink: drink)
                        .modifier(TabBarHidden())
                case .DrinkDetailWithUsedTo(let drink, let usedTo):
                    DrinkDetailView(drink: drink, usedTo: usedTo)
                        .modifier(TabBarHidden())
                case .PostDetail(let postUserType,
                                 let post,
                                 let usedTo):
                    PostDetailView(postUserType: postUserType,
                                   post: post,
                                   usedTo: usedTo)
                    .modifier(TabBarHidden())
                default:
                    ErrorPageView()
                        .modifier(TabBarHidden())
                }
            }
            // 시작할 때, 데이터 받아오기
            .task {
                if drinkViewModel.drinks.isEmpty {
                    await drinkViewModel.loadDrinksFirstPage()
                }
            }
            .onAppear {
                appViewModel.tabBarState = .visible
            }
        }
        .environmentObject(navigationRouter)
        .toolbar(appViewModel.tabBarState, for: .tabBar)
	}
}

#Preview {
	DrinkInfoView()
}
