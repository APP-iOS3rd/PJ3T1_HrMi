//
//  Errors.swift
//  JUDA
//
//  Created by phang on 2/7/24.
//

import Foundation

// MARK: - PhotosPicker 에서 이미지 로드 실패 에러
enum PhotosPickerImageLoadingError: Error {
    case invalidImageData
}

// MARK: - AuthManager 에서 사용 할 Error
enum AuthManagerError: Error {
    case noUser
    case noUserID
    case noProviderData
}

// MARK: - User Fetch
enum FetchUserError: Error {
    case userField
    case writtenPosts
    case likedPosts
    case likedDrinks
    case notifications
}

// MARK: - Weather Fetch Error
enum WeatherFetchError: Error {
    case fetchWeather
    case shouldFetch
}

// MARK: - Fire Storage 관련 Error
enum FireStorageError: Error {
    case getFileName
    case uploadImage
    case fetchImageURL
}

// MARK: - Token Request Error
enum TokenRequest: Error {
    case getToken
}

// MARK: - Post 관련 에러 : Firestore
enum PostError: Error {
    case fieldFetch
    case documentFetch
    case collectionFetch
    case upload
    case update
    case delete
}

// MARK: - Drink 관련 에러 : Firestore
enum DrinkError: Error {
    case fetchDrinkField
    case fetchDrinkDocument
    case fetchDrinkCollection
    case delete
}
