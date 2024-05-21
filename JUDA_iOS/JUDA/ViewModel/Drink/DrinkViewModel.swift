//
//  DrinkViewModel.swift
//  JUDA
//
//  Created by phang on 3/8/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

// MARK: - Drink View Model
@MainActor
final class DrinkViewModel: ObservableObject {
    // 술 리스트
    @Published var drinks = [Drink]()
    // 그리드 or 리스트
    @Published var selectedViewType: DrinkInfoLayoutOption = .gridStyle
    // 술 종류 선택 segment Index
    @Published var selectedDrinkTypeIndex: Int = 0
    // 술 정렬 방식 선택
    @Published var selectedSortedTypeString: String = DrinkSortType.popularity.rawValue
    // 로딩 중 - Shimmer Drink List / Grid Cell
    @Published var isLoading: Bool = true
    // 검색 중 -
    @Published var isSearching: Bool = false
    // pagination 을 위한, 이전 load의 마지막 체크
    private var lastSnapshot: QueryDocumentSnapshot?
    // pagination 할 documet 개수
    private let paginationCount = 20
    // FireStore 기본 경로
    private let db = Firestore.firestore()
    private let drinkCollection = "drinks"
    // Firestore Drink Service
    private let firestoreDrinkService = FirestoreDrinkService()
    // Fire Storage Service
    private let fireStorageService = FireStorageService()
    // AI WellMatch Service - DrinkDetail 의 '어울리는 음식 추천'에서 사용
    private let aiWellMatchService = AIWellMatchService()

    
    // 선택된 술 종류(카테고리)에 따라 Query 설정
    private func getReference(category: DrinkType) -> Query {
        let drinkRef = db.collection(drinkCollection)
        switch category {
        case .all:
            return drinkRef
        case .beer:
            return drinkRef.whereField("category", isEqualTo: DrinkType.beer.rawValue)
        case .traditional:
            return drinkRef.whereField("category", isEqualTo: DrinkType.traditional.rawValue)
        case .whiskey:
            return drinkRef.whereField("category", isEqualTo: DrinkType.whiskey.rawValue)
        case .wine:
            return drinkRef.whereField("category", isEqualTo: DrinkType.wine.rawValue)
        }
    }
    
    // 선택된 술 정렬 방식에 따라 Query 설정
    private func getReference(sortType: DrinkSortType?, query: Query) -> Query {
        switch sortType {
        // 인기순 - 내림차순
        case .popularity:
            return query.order(by: "rating", descending: true)
        // 도수 높은 순 - 내림차순
        case .highAlcoholContent:
            return query.order(by: "alcohol", descending: true)
        // 도수 낮은 순
        case .lowAlcoholContent:
            return query.order(by: "alcohol")
        // 금액 높은 순 - 내림차순
        case .highPrice:
            return query.order(by: "price", descending: true)
        // 금액 낮은 순
        case .lowPrice:
            return query.order(by: "price")
        // default == popularity
        default:
            return query.order(by: "rating", descending: true)
        }
    }
}

// MARK: - Fetch
// 술 데이터 불러오기 / 페이지네이션 ( FirestoreDrinkService )
extension DrinkViewModel {
    // 첫 데이터 20개 가져오기
    func loadDrinksFirstPage() async {
        self.isLoading = true
        let collectionRef = getReference(
            sortType: DrinkSortType(rawValue: selectedSortedTypeString),
            query: getReference(category: DrinkType.list[selectedDrinkTypeIndex]))
            .limit(to: paginationCount)
        self.drinks.removeAll() // 기존 술 배열 비우기
        do {
            let drinksSnapshot = try await collectionRef.getDocuments()
            self.lastSnapshot = drinksSnapshot.documents.last
            await fetchDrinks(querySnapshot: drinksSnapshot)
        } catch {
            print("error :: loadDrinksFirstPage", error.localizedDescription)
        }
        self.isLoading = false
    }
    
    // 추가적인 데이터 가져오기
    func loadDrinksNextPage() async {
        guard let lastSnapshot = self.lastSnapshot else {
            print("error :: loadDrinksNextPage - lastSnapshot X")
            return
        }
        let collectionRef = getReference(
            sortType: DrinkSortType(rawValue: selectedSortedTypeString),
            query: getReference(category: DrinkType.list[selectedDrinkTypeIndex]))
            .start(afterDocument: lastSnapshot)
            .limit(to: paginationCount)
        do {
            let drinksSnapshot = try await collectionRef.getDocuments()
            self.lastSnapshot = drinksSnapshot.documents.last
            await fetchDrinks(querySnapshot: drinksSnapshot)
        } catch {
            print("error :: loadDrinksNextPage", error.localizedDescription)
        }
    }
    
    // 데이터 가져오기
    func fetchDrinks(querySnapshot: QuerySnapshot) async {
        do {
            for drinkDocument in querySnapshot.documents {
                let drinkID = drinkDocument.documentID
                let documentRef = db.collection(drinkCollection).document(drinkID)
                let drinkData = try await firestoreDrinkService.fetchDrinkDocument(document: documentRef)
                self.drinks.append(drinkData)
            }
        } catch {
            print("error :: fetchDrinks", error.localizedDescription)
        }
    }
}

// MARK: - Fetch in Drink Detail View
extension DrinkViewModel {
    // DrinkDetail 의 '잘 어울리는 음식' 추천에서 openAI 에게 추천 받아오기
    func getFoodRecommendationsToOpenAI(drinkName: String) async -> String {
        let result = await aiWellMatchService.fetchRecommendationsIfNeeded(drinkName: drinkName)
        guard let result = result else { return "-" }
        return result
    }
    
    // '태그된 게시물' 인기순으로 최대 3개만 받아오기
    func getTopTrendingPosts(drink: Drink) -> [Post] {
        let posts = drink.taggedPosts
        let sortedPosts = posts.sorted {
            $0.likedUsersID.count > $1.likedUsersID.count
        }.prefix(3)
        return Array(sortedPosts)
    }
    
    // shareLink 에서 사용 할, Image 단일 받아오기
    // 이미지 못받는 경우, 앱 로고 사용
    func getDrinkImage(url: URL?) async -> Image {
        do {
            guard let url = url else { return Image("AppIcon") }
            let uiImage = try await fireStorageService.getUIImageFile(url: url.absoluteString)
            guard let uiImage = uiImage else { return Image("AppIcon") }
            return Image(uiImage: uiImage)
        } catch {
            print("error :: getDrinkImage", error.localizedDescription)
            return Image("AppIcon")
        }
    }
}

// MARK: - Fetch in Post Detail View
extension DrinkViewModel {
    // PostDetail 에서 Post 에 태그된 술의 정보를 다 갖고 있지 않으니, Drinks 를 받아오기
    func getPostTaggedDrinks(drinksID: [String]) async -> [Drink] {
        var result = [Drink]()
        do {
            for drinkID in drinksID {
                let documentRef = db.collection(drinkCollection).document(drinkID)
                let drinkData = try await firestoreDrinkService.fetchDrinkDocument(document: documentRef)
                result.append(drinkData)
            }
        } catch {
            print("error :: getPostTaggedDrinks", error.localizedDescription)
        }
        return result
    }
    
    // post 에 등록된 drinkRating 을 가져오기 위한 메서드
    func getDrinkRating(drinkTags: [DrinkTag], drink: Drink) -> Double {
        drinkTags.filter {
            $0.drinkID == drink.drinkField.drinkID
        }.first?.drinkRating ?? 0
    }
}

// MARK: - Search
extension DrinkViewModel {
    // 술 검색해서 데이터 받아오기
    // 검색된 술 데이터는 사용처에서 @State 로 사용
    func getSearchedDrinks(from keyword: String) async -> [Drink] {
        self.isSearching = true
        var result = [Drink]()
        do {
            let collectionRef = db.collection(drinkCollection)
            let drinksSnapshot = try await collectionRef.getDocuments()
            for drinkDocument in drinksSnapshot.documents {
                let drinkFieldData = try drinkDocument.data(as: DrinkField.self)
                if isKeywordInName(drinkFieldData: drinkFieldData, keyword: keyword) {
                    let drinkID = drinkDocument.documentID
                    let documentRef = collectionRef.document(drinkID)
                    let drinkData = try await firestoreDrinkService.fetchDrinkDocument(document: documentRef)
                    result.append(drinkData)
                }
            }
        } catch {
            print("error :: getSearchedDrinks", error.localizedDescription)
        }
        self.isSearching = false
        return result
    }
    
    // keyword 가 술 이름에 포함 되어있는지
    private func isKeywordInName(drinkFieldData: DrinkField, keyword: String) -> Bool {
        return drinkFieldData.name.localizedCaseInsensitiveContains(keyword)
    }
}
