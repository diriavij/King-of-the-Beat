import Foundation

final class ResultsInteractor: ResultsBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: ResultsPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: ResultsPresentationLogic) {
        self.presenter = presenter
    }
    
    func fetchTopThree(completion: @escaping ([Track]) -> Void) {
        guard let roomId = UserDefaults.standard.string(forKey: "Room"),
              let url = URL(string: "http://localhost:8080/room/results?roomId=\(roomId)") else {
            print("[ResultsInteractor] invalid RoomId or URL")
            completion([])
            return
        }
        
        print("[ResultsInteractor]  fetchTopThree: sending request to \(url)")
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("[ResultsInteractor] network error:", error)
                completion([])
                return
            }
            
            if let http = response as? HTTPURLResponse {
                print("[ResultsInteractor] status code:", http.statusCode)
            }
            
            guard let data = data else {
                print("[ResultsInteractor] no data received")
                completion([])
                return
            }
            
            if let raw = String(data: data, encoding: .utf8) {
                print("[ResultsInteractor] raw response:\n\(raw)")
            }
            
            do {
                let tracks = try JSONDecoder().decode([Track].self, from: data)
                print("[ResultsInteractor] decoded tracks:", tracks)
                completion(tracks)
            } catch {
                print("[ResultsInteractor] decode error:", error)
                completion([])
            }
        }.resume()
    }
    
    func fetchAllSongs(completion: @escaping ([Track]) -> Void) {
        guard let roomId = UserDefaults.standard.string(forKey: "Room"),
              let url = URL(string: "http://localhost:8080/room/all-songs?roomId=\(roomId)") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let tracks = try? JSONDecoder().decode([Track].self, from: data) else {
                completion([]); return
            }
            completion(tracks)
        }.resume()
    }
}
