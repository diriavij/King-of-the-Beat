import Foundation
import Combine

final class RoomViewModel {
    @Published var participants: [String] = []
    private var cancellables: Set<AnyCancellable> = []
    
    func listenForUpdates() {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            let newPlayer = "Player \(Int.random(in: 7...99))"
            self?.participants.append(newPlayer)
        }
    }
}
