//
//  PostService.swift
//  JUDA
//
//  Created by Minjae Kim on 3/8/24.
//

import SwiftUI
import FirebaseFirestore

// MARK: - Post View Model ( 술상 )
@MainActor
final class PostViewModel: ObservableObject {
    private let db = Firestore.firestore() // 파이어베이스 연결
	private let postCollection = "posts"
	private let firestorePostService = FirestorePostService()
    private let firestoreDrinkService = FirestoreDrinkService()
	private let firestoreReportService = FirestoreReportService()
    private let fireStorageService = FireStorageService()
	
	private var listener: ListenerRegistration?
	
	private(set) var searchPostsByUserNameCount = 0
	private(set) var searchPostsByDrinkTagCount = 0
	private(set) var searchPostsByFoodTagCount = 0
	
	// 게시글 객체 배열
	@Published var posts = [Post]()
    // 이름으로 검색된 게시글 객체 배열
    @Published var searchPostsByUserName = [Post]()
    // 술 태그로 검색된 게시글 객체 배열
    @Published var searchPostsByDrinkTag = [Post]()
    // 음식 태그로 검색된 게시글 객체 배열
    @Published var searchPostsByFoodTag = [Post]()
    // DrinkDetail 에서 이동했을 때, '태그된 게시글' 객체 정렬해서 사용할 배열
    @Published var drinkTaggedPosts = [Post]()
    // 게시글 정렬 방식 선택
    @Published var selectedSegmentIndex = 0
	// 마지막 포스트 확인용(페이징)
	@Published var lastQuerydocumentSnapshot: QueryDocumentSnapshot?
	// 게시글 불러오기 또는 삭제 작업이 진행중인지 나타내는 상태 프로퍼티
    @Published var isLoading = false
    // 검색 중
	@Published var isSearching = false
}

// MARK: - Fetch
extension PostViewModel {
    // 술상 정렬 타입 ( 인기순 / 최신순 )
	func getPostSortType(postSortType: PostSortType) -> Query {
		let postRef = db.collection(postCollection)
		
		switch postSortType {
		case .popularity:
			return postRef.order(by: "likedCount", descending: true)
		case .mostRecent:
			return postRef.order(by: "postedTime", descending: true)
		}
	}
	
    // 술상 첫 20개 불러오기 - 페이지네이션
	func fetchFirstPost() async {
		do {
            let query = getPostSortType(postSortType: PostSortType.list[selectedSegmentIndex])
			let firstSnapshot = try await query.limit(to: 20).getDocuments()
			lastQuerydocumentSnapshot = firstSnapshot.documents.last
			isLoading = true
            posts.removeAll()
			await fetchPosts(querySnapshots: firstSnapshot)
		} catch {
			print("posts paging fetch error \(error.localizedDescription)")
		}
	}
	
    // 술상 다음 20개 불러오기 - 페이지네이션
	func fetchNextPost() async {
        let query = getPostSortType(postSortType: PostSortType.list[selectedSegmentIndex])
		guard let lastQuerydocumentSnapshot = lastQuerydocumentSnapshot else { return }
		do {
			let nextSnapshot = try await query.limit(to: 20).start(afterDocument: lastQuerydocumentSnapshot).getDocuments()
			self.lastQuerydocumentSnapshot = nextSnapshot.documents.last
			await fetchPosts(querySnapshots: nextSnapshot)
		} catch {
			print("posts paging fetch error \(error.localizedDescription)")
		}
	}
	
    // Post 데이터 받아오기
	private func fetchPosts(querySnapshots: QuerySnapshot) async {
		var tasks: [Task<(Int, Post)?, Error>] = []
        
        for (index, document) in querySnapshots.documents.enumerated() {
			let task = Task<(Int, Post)?, Error> {
				do {
					let post = try await firestorePostService.fetchPostDocument(document: document.reference)
					return (index, post)
				} catch PostError.fieldFetch {
					print("error :: fetchPostField() -> fetch post field data failure")
					return nil
				} catch PostError.documentFetch {
					print("error :: fetchPostDocument() -> fetch post document data failure")
					return nil
				}
			}
			tasks.append(task)
		}
		
		var results = [(Int, Post)]()
		for task in tasks {
			do {
				if let result = try await task.value {
					results.append(result)
				}
			} catch {
				print(error.localizedDescription)
			}
		}
		results.sort { $0.0 < $1.0 }
		
		let posts = results.map { $0.1 }
		
		self.posts.append(contentsOf: posts)
		self.isLoading = false
	}
}

// MARK: - Fetch in Post Detail
extension PostViewModel {
    // shareLink 에서 사용 할, Image 단일 받아오기
    // 이미지 못받는 경우, 앱 로고 사용
    func getPostThumbnailImage(url: URL?) async -> Image {
        do {
            guard let url = url else { return Image("AppIcon") }
            let uiImage = try await fireStorageService.getUIImageFile(url: url.absoluteString)
            guard let uiImage = uiImage else { return Image("AppIcon") }
            return Image(uiImage: uiImage)
        } catch {
            print("error :: getPostThumbnailImage", error.localizedDescription)
            return Image("AppIcon")
        }
    }
}

// MARK: - Delete
extension PostViewModel {
    // post 삭제
	func deletePost(userID: String, postID: String) async {
        do {
            let documentRef = db.collection(postCollection).document(postID)
			// root post document 삭제 후
            try await firestorePostService.deletePostDocument(document: documentRef)
			// 연관된 document 삭제
			firestorePostService.deleteRelatedPostDocument(userID: userID, postID: postID)
        } catch {
            print("error :: deletePost", error.localizedDescription)
        }
    }
}

// MARK: - Update
extension PostViewModel {
    // post 수정
    func editPost(postID: String, content: String?, foodTags: [String]?) async {
        do {
            let collectionRef = db.collection(postCollection)
            if let content = content {
                try await firestorePostService.updatePostField(ref: collectionRef,
                                                               postID: postID,
                                                               data: ["content": content])
            }
            if let foodTags = foodTags {
                try await firestorePostService.updatePostField(ref: collectionRef,
                                                               postID: postID,
                                                               data: ["foodTags": foodTags])
            }
        } catch {
            print("error :: editPost", error.localizedDescription)
        }
    }
}

// MARK: - Search
extension PostViewModel {
    // 게시글 검색해서 데이터 받아오기
    func getSearchedPosts(from keyword: String) async {
        self.isSearching = true
        do {
            let collectionRef = db.collection(postCollection)
            let postSnapshot = try await collectionRef.getDocuments()
            for postDocument in postSnapshot.documents {
                let postFieldData = try postDocument.data(as: PostField.self)
                let postID = postDocument.documentID
                let documentRef = collectionRef.document(postID)
                
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await self.updateSearchResults(for: .userName, postField: postFieldData,
                                                       keyword: keyword, documentRef: documentRef)
                    }
                    group.addTask {
                        await self.updateSearchResults(for: .drinkTag, postField: postFieldData,
                                                       keyword: keyword, documentRef: documentRef)
                    }
                    group.addTask {
                        await self.updateSearchResults(for: .foodTag, postField: postFieldData,
                                                       keyword: keyword, documentRef: documentRef)
                    }
                }
            }
        } catch {
            print("error :: getSearchedPosts", error.localizedDescription)
        }
        self.isSearching = false
    }
    
    // searchPostsBy... 배열에 값을 채워주는 메서드
    private func updateSearchResults(for category: SearchTagType, postField: PostField, keyword: String, documentRef: DocumentReference) async {
        do {
            switch category {
            case .userName:
                if isKeywordInUserName(postField: postField, keyword: keyword) {
                    let postData = try await firestorePostService.fetchPostDocument(document: documentRef)
                    self.searchPostsByUserName.append(postData)
                }
            case .drinkTag:
                if isKeywordInDrinkTags(postField: postField, keyword: keyword) {
                    let postData = try await firestorePostService.fetchPostDocument(document: documentRef)
                    self.searchPostsByDrinkTag.append(postData)
                }
            case .foodTag:
                if isKeywordInFoodTags(postField: postField, keyword: keyword) {
                    let postData = try await firestorePostService.fetchPostDocument(document: documentRef)
                    self.searchPostsByFoodTag.append(postData)
                }
            }
        } catch {
            print("error :: updateSearchResults", error.localizedDescription)
        }
    }
	
	func getSearchedPostsCount(from keyword: String) async {
		self.isSearching = true
		self.searchPostsByUserNameCount = 0
		self.searchPostsByDrinkTagCount = 0
		self.searchPostsByFoodTagCount = 0
		
		do {
			let collectionRef = db.collection(postCollection)
			let postSnapshot = try await collectionRef.getDocuments()
			for postDocument in postSnapshot.documents {
				let postFieldData = try postDocument.data(as: PostField.self)
				let postID = postDocument.documentID
				let documentRef = collectionRef.document(postID)
				
				await withTaskGroup(of: Void.self) { group in
					group.addTask {
						await self.countBySearchType(for: .userName, postField: postFieldData,
													   keyword: keyword, documentRef: documentRef)
					}
					group.addTask {
						await self.countBySearchType(for: .drinkTag, postField: postFieldData,
													   keyword: keyword, documentRef: documentRef)
					}
					group.addTask {
						await self.countBySearchType(for: .foodTag, postField: postFieldData,
													   keyword: keyword, documentRef: documentRef)
					}
				}
			}
		} catch {
			print("error :: getSearchedPostsCount", error.localizedDescription)
		}
		self.isSearching = false
	}
	
	private func countBySearchType(for category: SearchTagType, postField: PostField, keyword: String, documentRef: DocumentReference) async {
		do {
			switch category {
			case .userName:
				let postData = try await firestorePostService.fetchPostDocument(document: documentRef)
				if isKeywordInUserName(postField: postData.postField, keyword: keyword) {
					self.searchPostsByUserNameCount += 1
				}
			case .drinkTag:
				let postData = try await firestorePostService.fetchPostDocument(document: documentRef)
				if isKeywordInDrinkTags(postField: postData.postField, keyword: keyword) {
					self.searchPostsByDrinkTagCount += 1
				}
			case .foodTag:
				let postData = try await firestorePostService.fetchPostDocument(document: documentRef)
				if isKeywordInFoodTags(postField: postData.postField, keyword: keyword) {
					self.searchPostsByFoodTagCount += 1
				}
			}
		} catch {
			print("error :: updateSearchResults", error.localizedDescription)
		}
	}
	
	func getSearchedPosts2(from keyword: String, category: SearchTagType) async -> [Post] {
		self.isSearching = true
		
		var searchPosts = [Post]()
		
		do {
			let collectionRef = db.collection(postCollection)
			let postSnapshot = try await collectionRef.getDocuments()
			for postDocument in postSnapshot.documents {
				let postFieldData = try postDocument.data(as: PostField.self)
				let postID = postDocument.documentID
				let documentRef = collectionRef.document(postID)
				
				if let post = await self.updateSearchResults2(for: category, postField: postFieldData,
															  keyword: keyword, documentRef: documentRef) {
					searchPosts.append(post)
				}
			}
//			return searchPosts
		} catch {
			print("error :: getSearchedPosts", error.localizedDescription)
		}
		self.isSearching = false
		return searchPosts
	}
	
	private func updateSearchResults2(for category: SearchTagType, postField: PostField, keyword: String, documentRef: DocumentReference) async -> Post? {
		do {
			switch category {
			case .userName:
				let postData = try await firestorePostService.fetchPostDocument(document: documentRef)
				if isKeywordInUserName(postField: postData.postField, keyword: keyword) {
					return postData
				}
			case .drinkTag:
				let postData = try await firestorePostService.fetchPostDocument(document: documentRef)
				if isKeywordInDrinkTags(postField: postData.postField, keyword: keyword) {
					return postData
				}
			case .foodTag:
				let postData = try await firestorePostService.fetchPostDocument(document: documentRef)
				if isKeywordInFoodTags(postField: postData.postField, keyword: keyword) {
					return postData
				}
			}
		} catch {
			print("error :: updateSearchResults", error.localizedDescription)
		}
		return nil
	}
    
    // 키워드가 post 를 작성한 유저의 이름에 포함되는지
    private func isKeywordInUserName(postField: PostField, keyword: String) -> Bool {
        return postField.user.userName.localizedCaseInsensitiveContains(keyword)
    }

    // 키워드가 post 에 태그된 술의 이름에 포함되는지
    private func isKeywordInDrinkTags(postField: PostField, keyword: String) -> Bool {
        return postField.drinkTags.contains {
            $0.drinkName.localizedCaseInsensitiveContains(keyword)
        }
    }

    // 키워드가 post 에 태그된 음식의 이름에 포함되는지
    private func isKeywordInFoodTags(postField: PostField, keyword: String) -> Bool {
        return postField.foodTags.contains {
            $0.localizedCaseInsensitiveContains(keyword)
        }
    }
    
}

// MARK: - Sort Post ( 태그된 게시글 / 검색된 게시글 )
extension PostViewModel {
    // 이미 가지고 있는 배열 정렬
    func sortedPosts(_ postData: [Post], postSortType: PostSortType) async -> [Post] {
        var result = [Post]()
        if postSortType == .popularity {
            result = postData.sorted {
				$0.postField.likedCount > $1.postField.likedCount
            } // 인기순
        } else {
            result = postData.sorted { 
                $0.postField.postedTime > $1.postField.postedTime
            } // 최신순
        }
        return result
    }
    
    // '검색된 게시글' 배열 정렬
    func sortedSearchedPosts(searchTagType: SearchTagType, postSortType: PostSortType) async {
        let postsToSort: [Post]
        switch searchTagType {
        case .userName:
            postsToSort = searchPostsByUserName
        case .drinkTag:
            postsToSort = searchPostsByDrinkTag
        case .foodTag:
            postsToSort = searchPostsByFoodTag
        }
        let result = await sortedPosts(postsToSort, postSortType: postSortType)
        switch searchTagType {
        case .userName:
            searchPostsByUserName = result
        case .drinkTag:
            searchPostsByDrinkTag = result
        case .foodTag:
            searchPostsByFoodTag = result
        }
    }
	
	// '검색된 게시글' 배열 요소 전체 삭제
	func clearSearchedPosts() {
		searchPostsByUserName = []
		searchPostsByDrinkTag = []
		searchPostsByFoodTag = []
	}
}

// MARK: - real time database with firestore
extension PostViewModel {
	func startListening() async {
		listener = db.collection(postCollection).addSnapshotListener { querySnapshot, error in
			guard let snapshot = querySnapshot, error == nil else {
				print("Error fetching snapshots: \(error!)")
				return
			}
			
			snapshot.documentChanges.forEach { diff in
				do {
					// 게시글이 추가된 경우, 술상 정렬타입이 인기순이라면 배열의 0번째에 추가
					if diff.type == .added, self.selectedSegmentIndex == 1 {
						let postField = try diff.document.data(as: PostField.self)
						self.posts.insert(Post(postField: postField, likedUsersID: []), at: 0)
					}
					// 게시글이 수정된 경우, 해당 게시글이 배열에 존재하면 해당 인덱스에 수정사항 반영
					if diff.type == .modified {
						let postField = try diff.document.data(as: PostField.self)
						if let index = self.posts.firstIndex(where: { $0.postField.postID == postField.postID }) {
							self.posts[index].postField = postField
						}
					}
					// 게시글이 삭제된 경우, 해당 게시글이 배열에 존재하면 배열에서 삭제
					if diff.type == .removed {
						let postField = try diff.document.data(as: PostField.self)
						if let index = self.posts.firstIndex(where: { $0.postField.postID == postField.postID }) {
							self.posts.remove(at: index)
						}
					}
				} catch {
					print(error.localizedDescription)
				}
			}
		}
	}
	
	func stopListening() {
		listener?.remove()
	}
}

// MARK: - Report Upload
extension PostViewModel {
    // 신고 등록
    func uploadPostReport(_ report: Report) async {
        do {
            try await firestoreReportService.uploadReport(report: report)
        } catch {
            print("error :: uploadPostReport", error.localizedDescription)
        }
    }
}
