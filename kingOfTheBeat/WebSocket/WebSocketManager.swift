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
            
            self?.receiveMessage()
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
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

extension Notification.Name {
    static let participantsUpdated = Notification.Name("participantsUpdated")
}
