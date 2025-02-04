//
//  WebSocketManager.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 03.02.2025.
//

import Foundation

class WebSocketManager {
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    
    func connect() {
        guard let url = URL(string: "ws://localhost:8080/ws") else { return }
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("📩 Получено сообщение: \(text)")
                    self?.handleParticipantsUpdate(json: text)
                default:
                    break
                }
            case .failure(let error):
                print("Ошибка получения сообщения: \(error.localizedDescription)")
            }
            
            // Повторяем чтение сообщений
            self?.receiveMessage()
        }
    }
    
    // Закрытие WebSocket-соединения
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    // Обработка обновлений списка участников
    private func handleParticipantsUpdate(json: String) {
        guard let data = json.data(using: .utf8) else { return }
        do {
            let participants = try JSONDecoder().decode([User].self, from: data)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .participantsUpdated, object: participants)
            }
        } catch {
            print("Ошибка декодирования JSON: \(error.localizedDescription)")
        }
    }
}

// Расширение для удобного использования NotificationCenter
extension Notification.Name {
    static let participantsUpdated = Notification.Name("participantsUpdated")
}
