//
//  FirestorePostViewModel.swift
//  JUDA
//
//  Created by Minjae Kim on 3/5/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
final class FirestorePostService {
	lazy var functions = Functions.functions()
}

// MARK: - Firestore post fetch
extension FirestorePostService {
    // Post 리스트를 가져오는 함수
    // Post 를 단일로 가져오는 firestorePostViewModel 의 fetchPostDocument 을 사용.
    func fetchPostCollection(collection: CollectionReference, query: Query? = nil) async throws -> [Post] {
        do {
            var result = [Post]()
            var snapshot: QuerySnapshot
            // Post 가져오는 코드 - FirestorePostViewModel
            if let query = query {
                snapshot = try await query.getDocuments()
            } else {
                snapshot = try await collection.getDocuments()
            }
            for document in snapshot.documents {
                let id = document.documentID
                let documentRef = collection.document(id)
                let postData = try await fetchPostDocument(document: documentRef)
                result.append(postData)
            }
            return result
        } catch let error {
            print("error :: fetchPostCollection", error.localizedDescription)
            throw PostError.collectionFetch
        }
    }

	// posts collection의 post document data 불러오는 메서드
	// 불러오지 못 할 수 경우 error throw
	func fetchPostDocument(document: DocumentReference) async throws -> Post {
		do {
			let postField = try await fetchPostField(document: document)
			let likedUsersIDRef = document.collection("likedUsersID")
			let likedUsersID: [String] = await fetchPostLikedUsersID(ref: likedUsersIDRef)
			
			return Post(postField: postField, likedUsersID: likedUsersID)
		} catch PostError.fieldFetch {
			print("error :: fetchPostField() -> fetch post field data failure")
			throw PostError.fieldFetch
		} catch {
			print("error :: fetchPostDocument() -> fetch post document data failure")
			throw PostError.documentFetch
		}
	}
	
	// posts collection의 Field data 불러오는 메서드
	// 불러오지 못 할 수 경우 error throw
	func fetchPostField(document: DocumentReference) async throws -> PostField {
		do {
			return try await document.getDocument(as: PostField.self)
		} catch {
			print(error.localizedDescription)
			throw PostError.fieldFetch
		}
	}
	
	// posts collection의 하위 collection likedUsersID의 id 전부 불러오는 메서드
	// fetch 에러를 던질 시, 해당 값을 배열에 추가되지 않음
	func fetchPostLikedUsersID(ref: CollectionReference) async -> [String] {
		var likedUsersID = [String]()
		
		do {
			let snapshot = try await ref.getDocuments()
			for document in snapshot.documents {
				let userID = document.documentID
				likedUsersID.append(userID)
			}
		} catch {
			print("error :: fetchPostLikedUsersID() -> fetch post likedUsersID collection data failure")
			print(error.localizedDescription)
		}
		return likedUsersID
	}
}

// MARK: Firestore post document upload
extension FirestorePostService {
    func uploadPostDocument(post: Post, postID: String) async throws {
		let postDocumentRef = Firestore.firestore().collection("posts").document(postID)
		let likedUsersIDCollectionRef = postDocumentRef.collection("likedUsersID")
		
		do {
			try postDocumentRef.setData(from: post.postField, merge: true)
			for userID in post.likedUsersID {
				do {
					try await likedUsersIDCollectionRef.document(userID).setData([:])
				} catch {
					print("error :: uploadPostDocument() -> upload post likedUsersID collection data failure")
					print(error.localizedDescription)
				}
			}
		} catch {
			print("error :: uploadPostDocument() -> upload post document data failure")
			print(error.localizedDescription)
			throw PostError.upload
		}
	}
    
    // likedUsersID 하위 컬렉션에 업로드
    func uploadPostLikedUsersID(collection: CollectionReference, uid: String) async {
        do {
            try await collection.document(uid).setData([:])
        } catch {
            print("error :: uploadPostLikedUsersID() -> upload post liked users id data failure")
            print(error.localizedDescription)
        }
    }
}

// MARK: Firestore post document delete
extension FirestorePostService {
	// posts collection에서 삭제하고싶은 post에 해당하는 document 삭제 메서드
    func deletePostDocument(document: DocumentReference) async throws {
		do {
			try await document.delete()
		} catch {
			print("error :: deletePostDocument() -> delete post document data failure")
			print(error.localizedDescription)
			throw PostError.delete
		}
	}
}

// MARK: Cloud Funtion post related document delete
extension FirestorePostService {
	func deleteRelatedPostDocument(userID: String, postID: String) {
		let reqData = [
			"userID": userID,
			"postID": postID
		]
		
		functions.httpsCallable("onPostDelete").call(reqData) { _, error in
			if let error = error as NSError? {
				print("error :: deleteRelatedPostDocument", error.localizedDescription)
			}
		}
	}
}

// MARK: Firestore post field data update
extension FirestorePostService {
	// posts collection에서 수정하고싶은 post에 해당하는 field data 업데이트 메서드
	func updatePostField(ref: CollectionReference, postID: String, data: [String: Any]) async throws {
		do {
			try await ref.document(postID).updateData(data)
		} catch {
			print("error :: updatePostField() -> update post field data failure")
			print(error.localizedDescription)
			throw PostError.update
		}
	}
}
