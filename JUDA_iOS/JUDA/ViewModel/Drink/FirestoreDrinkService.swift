//
//  FirestoreDrinkViewModel.swift
//  JUDA
//
//  Created by Minjae Kim on 3/5/24.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

@MainActor
final class FirestoreDrinkService {
    // Firestore Post Service
	private let firestorePostService = FirestorePostService()
}

// MARK: Firestore Fetch Data
extension FirestoreDrinkService {
    // Drink 리스트를 가져오는 함수
    // Drink 를 단일로 가져오는 firestoreDrinkViewModel 의 fetchDrinkDocument 을 사용.
    func fetchDrinkCollection(collection: CollectionReference, query: Query? = nil) async throws -> [Drink] {
        do {
            var result = [Drink]()
            var snapshot: QuerySnapshot
            // Drink 가져오는 코드 - FirestoreDrinkViewModel
            if let query = query {
                snapshot = try await query.getDocuments()
            } else {
                snapshot = try await collection.getDocuments()
            }
            for document in snapshot.documents {
                let id = document.documentID
                let documentRef = collection.document(id)
                let drinkData = try await fetchDrinkDocument(document: documentRef)
                result.append(drinkData)
            }
            return result
        } catch let error {
            print("error :: fetchDrinkCollection", error.localizedDescription)
            throw DrinkError.fetchDrinkCollection
        }
    }
    
	// drinks collection의 document data 불러오는 메서드
	// 불러오지 못 할 경우 error를 throw
    func fetchDrinkDocument(document: DocumentReference) async throws -> Drink {
        do {
            let taggedPostsRef = document.collection("taggedPosts")
            let agePreferenceUIDRef = document.collection("agePreferenceUID")
            let genderPreferenceUIDRef = document.collection("genderPreferenceUID")
            let likedUsersIDRef = document.collection("likedUsersID")
            
            // 병렬로 각각의 비동기 호출 시작
            async let drinkField = fetchDrinkField(document: document)
            async let taggedPosts = fetchTaggedPosts(ref: taggedPostsRef)
            async let agePreference = fetchAgePreferenceUID(ref: agePreferenceUIDRef)
            async let genderPreference = fetchGenderPreferenceUID(ref: genderPreferenceUIDRef)
            async let likedUsersID = fetchDrinkLikedUsersID(ref: likedUsersIDRef)
            
            // 모든 비동기 호출이 완료될 때까지 대기
            let (drikFieldResult, taggedPostsResult, agePreferenceResult, genderPreferenceResult, likedUsersIDResult) = try await (drinkField, taggedPosts, agePreference, genderPreference, likedUsersID)
            
            return Drink(drinkField: drikFieldResult,
                         taggedPosts: taggedPostsResult,
                         agePreference: agePreferenceResult,
                         genderPreference: genderPreferenceResult,
                         likedUsersID: likedUsersIDResult)
        } catch DrinkError.fetchDrinkField {
            print("error :: fetchDrinkField() -> fetch drink field data failure")
            throw DrinkError.fetchDrinkField
        } catch {
            print("error :: fetchDrinkField() -> fetch drink field data failure")
            print(error.localizedDescription)
            throw DrinkError.fetchDrinkDocument
        }
    }
	
	// drinks collection의 하위 collection인 taggedPosts document data 불러오는 메서드
	// 불러오지 못 할 경우 배열에 추가 x
	func fetchTaggedPosts(ref: CollectionReference) async -> [Post] {
		var taggedPosts = [Post]()
		
		do {
			let snapshot = try await ref.getDocuments()
			for document in snapshot.documents {
				let documentRef = document.reference
				let taggedPost = try await firestorePostService.fetchPostDocument(document: documentRef)
				
				taggedPosts.append(taggedPost)
			}
		} catch {
			print("error :: fetchTaggedPosts() -> fetch taggedPost document data failure")
			print(error.localizedDescription)
		}
		return taggedPosts
	}
	
	// drinks collection의 Field data 불러오는 메서드
	// 불러오지 못 할 경우 error를 throw
	func fetchDrinkField(document: DocumentReference) async throws -> DrinkField {
		do {
			return try await document.getDocument(as: DrinkField.self)
		} catch {
			print(error.localizedDescription)
			throw DrinkError.fetchDrinkField
		}
	}
	
	// drinks/agePreferenceUID collection
	// 각 '연령대'에 맞는 document에 접근하여 UsersID collection에 해당하는 ducument의 갯수를 count
	func fetchAgePreferenceUID(ref: CollectionReference) async -> AgePreference {
		var agePreference = AgePreference(twenty: 0, thirty: 0, fourty: 0, fifty: 0)
		do {
            async let twenty = ref.document(Age.twenty.rawValue).collection("usersID").getDocuments().count
            async let thirty = ref.document(Age.thirty.rawValue).collection("usersID").getDocuments().count
            async let fourty = ref.document(Age.fourty.rawValue).collection("usersID").getDocuments().count
            async let fifty = ref.document(Age.fifty.rawValue).collection("usersID").getDocuments().count
            
            let (twentyResult, thirtyResult, fourtyResult, fiftyResult) = try await (twenty, thirty, fourty, fifty)
            
            agePreference = AgePreference(twenty: twentyResult,
                                          thirty: thirtyResult,
                                          fourty: fourtyResult,
                                          fifty: fiftyResult)
		} catch {
			print("error :: fetchAgePreferenceUID() -> fetch agePreferece collection data failure")
			print(error.localizedDescription)
		}
		return agePreference
	}
	
	// drinks/genderPreferenceUID collection
	// 각 '성별'에 맞는 document에 접근하여 UsersID collection에 해당하는 ducument의 갯수를 count
	func fetchGenderPreferenceUID(ref: CollectionReference) async -> GenderPreference {
		var genderPreference = GenderPreference(male: 0, female: 0)
		do {
            async let male = ref.document(Gender.male.rawValue).collection("usersID").getDocuments().count
            async let female = ref.document(Gender.female.rawValue).collection("usersID").getDocuments().count
            let (maleResult, femaleResult) = try await (male, female)
            genderPreference = GenderPreference(male: maleResult,
                                                female: femaleResult)
		} catch {
			print("error :: fetchGenderPreferenceUID() -> fetch genderPreferece collection data failure")
			print(error.localizedDescription)
		}
		return genderPreference
	}
	
	// drinks/likedUsersID collection
	func fetchDrinkLikedUsersID(ref: CollectionReference) async -> [String] {
        var likedUsersID = [String]()
        do {
            let snapshot = try await ref.getDocuments()
            for document in snapshot.documents {
                let userID = document.documentID
                likedUsersID.append(userID)
            }
        } catch {
            print("error :: fetchDrinkLikedUsersID() -> fetch Drink likedUsersID collection data failure")
            print(error.localizedDescription)
        }
        return likedUsersID
	}
}

// MARK: Firestore drink field data update
extension FirestoreDrinkService {
	// drinks collection field data update 메서드
	func updateDrinkField(ref: CollectionReference, drinkID: String, data: [String: Any]) async {
		do {
			try await ref.document(drinkID).updateData(data)
		} catch {
			print("error :: drinkFieldUpdate() -> update drink field data failure")
			print(error.localizedDescription)
		}
	}
}

extension FirestoreDrinkService {
    // drink collection agePreference data update 메서드
    func updateDrinkAgePreference(ref: CollectionReference, drinkID: String, age: Age, userID: String) async {
        do {
            try await ref.document(drinkID).collection("agePreferenceUID").document(age.rawValue).collection("usersID").document(userID).setData([:])
        } catch {
            print("error :: updateDrinkAgePreference() -> upload userID to agePreference failure")
        }
    }
    
    // drink collection genderPreference data update 메서드
    func updateDrinkGenderPreference(ref: CollectionReference, drinkID: String, gender: String, userID: String) async {
        do {
            try await ref.document(drinkID).collection("genderPreferenceUID").document(gender).collection("usersID").document(userID).setData([:])
        } catch {
            print("error :: updateDrinkGenderPreference() -> upload userID to genderPreference failure")
        }
    }
}

// MARK: Firestore drink document delete
extension FirestoreDrinkService {
    // drinks collection에서 삭제하고싶은 drink에 해당하는 document 삭제 메서드
    func deleteDrinkDocument(document: DocumentReference) async throws {
        do {
            try await document.delete()
        } catch {
            print("error :: deleteDrinkDocument() -> delete drink document data failure")
            print(error.localizedDescription)
            throw DrinkError.delete
        }
    }
}

// MARK: Firestore drink document upload & delete
extension FirestoreDrinkService {
    // likedUsersID 하위 컬렉션에 업로드
    func uploadDrinkLikedUsersID(collection: CollectionReference, uid: String) async {
        do {
            try await collection.document(uid).setData([:])
        } catch {
            print("error :: uploadDrinkLikedUsersID() -> upload drink liked users id data failure")
            print(error.localizedDescription)
        }
    }
}
