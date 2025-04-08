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
        if let id = UserDefaults.standard.value(forKey: "UserId") as? Int {
            registerUser(with: id)
        } else {
            fetchRandomUserKey { key in
                guard let key = key else {
                    print("Failed to fetch user key")
                    return
                }
                
                if let id = Int(key) {
                    UserDefaults.standard.setValue(id, forKey: "UserId")
                    print("Generated key: \(id)")
                    self.registerUser(with: id)
                }
            }
        }
        presenter.routeToMain(IntroModels.Route.Response())
    }

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
                completion(key)
            } catch {
                print("Failed to decode response: \(error)")
                completion(nil)
            }
        }
        task.resume()
    }

    func registerUser(with id: Int) {
        let url = URL(string: "http://localhost:8080/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let apiService = APIService()

        apiService.getAccessToken { success in
            guard success else {
                print("Ошибка: не удалось получить токен.")
                return
            }

            DispatchQueue.main.async {
                print("Токен успешно получен: \(UserDefaults.standard.string(forKey: "Authorization") ?? "нет токена")")

                apiService.getProfileInfo { [weak self] url, name in
                    guard let self = self else { return }

                    if let url = url {
                        UserDefaults.standard.set(url.absoluteString, forKey: "PicUrl")
                    } else {
                        print("Ошибка: Не удалось получить URL изображения профиля.")
                        let placeholderURL = URL(string: "https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png")!
                        UserDefaults.standard.set(placeholderURL.absoluteString, forKey: "PicUrl")
                    }
                    UserDefaults.standard.set(name, forKey: "Name")

                    self.createUser(with: id)
                }
            }
        }
    }

    private func createUser(with id: Int) {
        let url = URL(string: "http://localhost:8080/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let newUser = User(
            userId: id,
            name: UserDefaults.standard.value(forKey: "Name") as? String ?? "",
            profilePic: UserDefaults.standard.value(forKey: "PicUrl") as? String ?? "https://developers.elementor.com/docs/assets/img/elementor-placeholder-image.png"
        )

        do {
            let requestBody = try JSONEncoder().encode(newUser)
            print("Запрос на создание пользователя: \(String(decoding: requestBody, as: UTF8.self))")
            request.httpBody = requestBody

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Ошибка при регистрации пользователя: \(error)")
                    return
                }

                print("Пользователь успешно создан")
            }
            task.resume()
        } catch {
            print("Ошибка при кодировании данных пользователя: \(error)")
        }
    }
}
