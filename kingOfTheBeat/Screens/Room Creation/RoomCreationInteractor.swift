//
//  RoomCreationInteractor.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 02.01.2025.
//

import Foundation

final class RoomCreationInteractor: RoomCreationBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: RoomCreationPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: RoomCreationPresentationLogic) {
        self.presenter = presenter
    }
    
    // MARK: - Methods
    
    func loadMainScreen(_ request: RoomCreationModels.RouteToMain.Request) {
        presenter.routeToMainScreen(RoomCreationModels.RouteToMain.Response())
    }
    
    private func fetchRandomRoomKey(completion: @escaping (String?) -> Void) {
        let url = URL(string: "http://localhost:8080/random-room-key")!
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
    
    private func registerRoom(with id: Int, _ name: String, completion: @escaping () -> Void) {
        let url = URL(string: "http://localhost:8080/rooms/create")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let newRoom = Room(roomId: id, name: name, ownerId: UserDefaults.standard.integer(forKey: "UserId"))

        do {
            let requestBody = try JSONEncoder().encode(newRoom)
            urlRequest.httpBody = requestBody

            URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    print("Error creating room: \(error)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Room creation failed with response: \(String(describing: response))")
                    return
                }

                print("Room created successfully")
                completion()
            }.resume()
        } catch {
            print("Failed to encode room: \(error)")
        }
    }

    func createRoom(_ request: RoomCreationModels.CreateRoom.Request) {
        fetchRandomRoomKey { key in
            guard let key = key, let id = Int(key) else {
                print("Failed to fetch room key")
                return
            }

            self.registerRoom(with: id, request.name) {
                // Сохраняем комнату только после успешной регистрации
                UserDefaults.standard.setValue(id, forKey: "Room")
                print("Room successfully created with ID: \(id)")
                DispatchQueue.main.async {
                    self.presenter.routeToRoomScreen(RoomCreationModels.CreateRoom.Response(name: request.name))
                }
            }
        }
    }
}

