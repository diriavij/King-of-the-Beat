//
//  IntroInteractor.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.01.2025.
//

import Foundation

// MARK: - IntroInteractor
class IntroInteractor: IntroBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: IntroPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: IntroPresentationLogic) {
        self.presenter = presenter
    }
    
    // MARK: - Methods
    
    func getAuthToken(_ request: IntroModels.Auth.Request) {
        let helper = APIService()
        guard let response = helper.getAccessTokenUrl() else { return }
        presenter.presentAuth(IntroModels.Auth.Response(response: response))
    }
    
    func loadMain(_ request: IntroModels.Route.Request) {
        // Проверяем, есть ли ID пользователя
        if let id = UserDefaults.standard.value(forKey: "UserId") as? Int {
            registerUser(with: id)
        } else {
            // Если ID нет, сначала запрашиваем ключ
            fetchRandomUserKey { key in
                guard let key = key else {
                    print("Failed to fetch user key")
                    return
                }
                
                // Регистрируем пользователя
                if let id = Int(key) {
                    UserDefaults.standard.setValue(id, forKey: "UserId")
                    print("Generated key: \(id)")
                    self.registerUser(with: id)
                }
            }
        }
        presenter.routeToMain(IntroModels.Route.Response())
    }

    // Функция для запроса случайного ключа
    func fetchRandomUserKey(completion: @escaping (String?) -> Void) {
        let url = URL(string: "http://localhost:8080/random-user-key")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching random user key: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data returned")
                completion(nil)
                return
            }

            do {
                let key = try JSONDecoder().decode(String.self, from: data)
                completion(key) // Возвращаем ключ через замыкание
            } catch {
                print("Failed to decode response: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }

    // Функция для регистрации пользователя
    func registerUser(with id: Int) {
        let url = URL(string: "http://localhost:8080/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newUser = User(userId: id)
        do {
            let requestBody = try JSONEncoder().encode(newUser)
            print(String(decoding: requestBody, as: UTF8.self))
            request.httpBody = requestBody

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error registering user: \(error)")
                    return
                }

                print("User created successfully")
                // Здесь вы можете вызвать presenter.routeToMain
            }
            task.resume()
        } catch {
            print("Failed to encode user: \(error)")
        }
    }
}
