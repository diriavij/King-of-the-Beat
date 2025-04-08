import Foundation

final class VotingInteractor: VotingBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: VotingPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: VotingPresentationLogic) {
        self.presenter = presenter
    }
    
    func resetVotesForRoom(roomId: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://localhost:8080/room/reset-bets-submitted?roomId=\(roomId)") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { _, response, error in
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(false)
                return
            }
            DispatchQueue.main.async { completion(true) }
        }.resume()
    }
    
    func fetchSongsForVoting(completion: @escaping ([Track]) -> Void) {
        guard let userId = UserDefaults.standard.value(forKey: "UserId") as? Int,
              let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            completion([])
            return
        }
        let url = URL(string: "http://localhost:8080/songs/for-voting?roomId=\(roomId)&userId=\(userId)")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            do {
                let tracks = try JSONDecoder().decode([Track].self, from: data)
                completion(tracks)
            } catch {
                completion([])
            }
        }.resume()
    }
    
    func fetchCurrentRoundForRoom(roomId: Int, completion: @escaping ([Track]) -> Void) {
        let url = URL(string: "http://localhost:8080/currentRound?roomId=\(roomId)")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            do {
                let tracks = try JSONDecoder().decode([Track].self, from: data)
                completion(tracks)
            } catch {
                completion([])
            }
        }.resume()
    }
    
    func advanceRound(roomId: Int, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: URL(string: "http://localhost:8080/room/determine-winner?roomId=\(roomId)")!)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { _, response, error in
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(false)
                return
            }
            DispatchQueue.main.async { completion(true) }
        }.resume()
    }
    
    func fetchBetsForVoting(completion: @escaping ([Bet]) -> Void) {
        guard let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            completion([])
            return
        }
        let url = URL(string: "http://localhost:8080/bets/for-voting?roomId=\(roomId)")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            do {
                let bets = try JSONDecoder().decode([Bet].self, from: data)
                completion(bets)
            } catch {
                completion([])
            }
        }.resume()
    }
    
    func sendVote(songId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = UserDefaults.standard.value(forKey: "UserId") as? Int,
              let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            completion(false)
            return
        }
        var request = URLRequest(url: URL(string: "http://localhost:8080/vote/submit")!)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "songId": songId,
            "userId": userId,
            "roomId": roomId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { _, response, error in
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(false)
                return
            }
            DispatchQueue.main.async { completion(true) }
        }.resume()
    }
    
    func getTotalBetsForSong(songId: Int, completion: @escaping (Int) -> Void) {
        guard let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            completion(0)
            return
        }
        let url = URL(string: "http://localhost:8080/bets/for-song?roomId=\(roomId)&songId=\(songId)")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(0)
                return
            }
            do {
                let bets = try JSONDecoder().decode([Bet].self, from: data)
                let total = bets.reduce(0) { $0 + $1.betAmount }
                completion(total)
            } catch {
                completion(0)
            }
        }.resume()
    }
    
    func checkIfAllVotesAreSubmitted(roomId: Int, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "http://localhost:8080/bets/all-submitted?roomId=\(roomId)")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let resp = try? JSONDecoder().decode([String: Bool].self, from: data),
                  let all = resp["allBetsSubmitted"] else {
                completion(false)
                return
            }
            DispatchQueue.main.async { completion(all) }
        }.resume()
    }
    
    func loadResultsScreen(_ request: VotingModels.RouteToResults.Request) {
        presenter.routeToResultsScreen(VotingModels.RouteToResults.Response())
    }
}
