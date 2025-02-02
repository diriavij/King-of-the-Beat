//
//  APIService.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 27.11.2024.
//

import Foundation

import Foundation

class APIService {
    func getAccessTokenUrl() -> URLRequest? {
        let worker = BaseUrlWorker(baseURL: APIConstants.authBaseUrl)
        let request = Request(endpoint: SpotifyAPIEndpoint.authorize)
        return worker.convert(request)
    }
    
    func getAccessToken(completion: @escaping (Bool) -> Void) {
        let worker = BaseUrlWorker(baseURL: APIConstants.authBaseUrl)
        let request = Request(endpoint: SpotifyAPIEndpoint.token, method: .post)
        
        worker.execute(with: request) { result in
            switch result {
            case .success(let response):
                if let httpResponse = response.response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let data = response.data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let accessToken = json?["access_token"] as? String,
                               let refreshToken = json?["refresh_token"] as? String {
                                UserDefaults.standard.setValue(accessToken, forKey: "Authorization")
                                UserDefaults.standard.setValue(refreshToken, forKey: "Refresh")
                                UserDefaults.standard.synchronize()
                                
                                print("Новые access и refresh токены сохранены.")
                                completion(true)
                            } else {
                                print("Ошибка: access_token или refresh_token отсутствуют в ответе.")
                                completion(false)
                            }
                        } catch {
                            print("Ошибка парсинга ответа токена: \(error)")
                            completion(false)
                        }
                    } else {
                        print("Ошибка: Нет данных в ответе токена.")
                        completion(false)
                    }
                } else {
                    if let httpResponse = response.response as? HTTPURLResponse,
                       let data = response.data,
                       let errorString = String(data: data, encoding: .utf8) {
                        print("Ошибка: \(httpResponse.statusCode) - \(errorString)")
                    } else {
                        print("Ошибка: Неожиданный статус код \(String(describing: response.response))")
                    }
                    completion(false)
                }
            case .failure(let error):
                print("Ошибка: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func renewAccessToken(completion: @escaping (Bool) -> Void) {
        let worker = BaseUrlWorker(baseURL: APIConstants.authBaseUrl) // "https://accounts.spotify.com"
        
        guard let refreshToken = UserDefaults.standard.string(forKey: "Refresh"), !refreshToken.isEmpty else {
            print("Ошибка: Refresh токен отсутствует.")
            completion(false)
            return
        }

        let parameters: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": APIConstants.clientId,
            "client_secret": APIConstants.clientSecret
        ]
        
        let request = Request(endpoint: SpotifyAPIEndpoint.refreshToken,
                              method: .post,
                              parameters: parameters)
        
        worker.execute(with: request) { result in
            switch result {
            case .success(let response):
                if let httpResponse = response.response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let data = response.data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let accessToken = json?["access_token"] as? String {
                                UserDefaults.standard.setValue(accessToken, forKey: "Authorization")
                                if let newRefreshToken = json?["refresh_token"] as? String {
                                    UserDefaults.standard.setValue(newRefreshToken, forKey: "Refresh")
                                }
                                print("Access токен обновлен.")
                                completion(true)
                            } else {
                                print("Ошибка: access_token отсутствует в ответе обновления.")
                                completion(false)
                            }
                        } catch {
                            print("Ошибка парсинга ответа обновления токена: \(error)")
                            completion(false)
                        }
                    } else {
                        print("Ошибка: Нет данных в ответе обновления токена.")
                        completion(false)
                    }
                } else {
                    if let httpResponse = response.response as? HTTPURLResponse,
                       let data = response.data,
                       let errorString = String(data: data, encoding: .utf8) {
                        print("Ошибка: \(httpResponse.statusCode) - \(errorString)")
                    } else {
                        print("Ошибка: Неожиданный статус код \(String(describing: response.response))")
                    }
                    completion(false)
                }
            case .failure(let error):
                print("Ошибка: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func getProfileInfo(completion: @escaping (URL?, String?) -> Void) {
        let worker = BaseUrlWorker(baseURL: APIConstants.apiBaseUrl)
        let request = Request(endpoint: SpotifyAPIEndpoint.profilePic)
        
        worker.execute(with: request) { result in
            switch result {
            case .success(let response):
                if let httpResponse = response.response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    print("Ошибка: Access токен истек. Статус код: \(httpResponse.statusCode)")
                    self.renewAccessToken { success in
                        if success {
                            self.getProfileInfo(completion: completion)
                        } else {
                            completion(nil, nil)
                        }
                    }
                    return
                }
                
                if let data = response.data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        let images = json?["images"] as? [[String: Any]]
                        let firstImage = images?.first
                        let imageUrlString = firstImage?["url"] as? String
                        let displayName = json?["display_name"] as? String
                        
                        let imageUrl = imageUrlString.flatMap { URL(string: $0) }
                        
                        completion(imageUrl, displayName)
                    } catch {
                        print("Ошибка парсинга ответа профиля: \(error)")
                        completion(nil, nil)
                    }
                } else {
                    print("Ошибка: Нет данных в ответе профиля.")
                    completion(nil, nil)
                }
            case .failure(let error):
                print("Ошибка: \(error.localizedDescription)")
                completion(nil, nil)
            }
        }
    }
}

enum SpotifyAPIEndpoint: Endpoint {
    case authorize
    case profilePic
    case refreshToken
    case token
    
    var compositePath: String {
        switch self {
        case .authorize:
            return "/authorize"
        case .profilePic:
            return "/v1/me"
        case .refreshToken:
            return "/api/token"
        case .token:
            return "/api/token"
        }
    }
    
    var headers: [String : String] {
        switch self {
        case .authorize:
            return [:]
        case .profilePic:
            guard let token = UserDefaults.standard.string(forKey: "Authorization"), !token.isEmpty else {
                print("Error: Authorization token is missing.")
                return [:]
            }
            return ["Authorization": "Bearer \(token)"]
        case .refreshToken:
            return ["Content-Type": "application/x-www-form-urlencoded"]
        case .token:
            let credentials = "\(APIConstants.clientId):\(APIConstants.clientSecret)"
            guard let data = credentials.data(using: .utf8) else {
                fatalError("Ошибка при конвертации данных в строку")
            }
            let base64String = data.base64EncodedString()
            return ["Content-Type": "application/x-www-form-urlencoded", "Authorization": "Basic \(base64String)"]
        }
    }
    
    var parameters: [String : String]? {
        switch self {
        case .authorize:
            return APIConstants.authParams
        case .profilePic:
            return [:]
        case .refreshToken:
            guard let refreshToken = UserDefaults.standard.string(forKey: "Refresh"), !refreshToken.isEmpty else {
                print("Error: Refresh token is missing.")
                return [:]
            }
            return [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken,
                "client_id": APIConstants.clientId,
                "client_secret": APIConstants.clientSecret
            ]
        case .token:
            return [
                "grant_type": "authorization_code",
                "code": UserDefaults.standard.string(forKey: "Code") ?? "",
                "redirect_uri": APIConstants.redirectUri
            ]
        }
    }
}

