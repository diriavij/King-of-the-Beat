import Foundation

final class MainInteractor: MainBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: MainPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: MainPresentationLogic) {
        self.presenter = presenter
    }
    
    // MARK: - Methods
    func loadCreationScreen(_ request: MainModels.RouteToCreation.Request) {
        presenter.routeToCreationScreen(MainModels.RouteToCreation.Response())
    }
    
    func loadRoomScreen(_ request: MainModels.RouteToRoom.Request) {
        presenter.routeToRoomScreen(MainModels.RouteToRoom.Response())
    }
    
    public func joinRoom(with code: Int, userId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:8080/room/add-user") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["userId": userId, "roomId": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка при попытке присоединиться к комнате:", error)
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }

            if httpResponse.statusCode == 200 {
                UserDefaults.standard.setValue(code, forKey: "Room")
                completion(true)
            } else {
                print("Не удалось присоединиться, код ответа:", httpResponse.statusCode)
                completion(false)
            }
        }.resume()
    }
}
