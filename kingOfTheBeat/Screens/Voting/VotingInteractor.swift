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
            print("Invalid URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending reset request:", error)
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server error or invalid response")
                completion(false)
                return
            }
            
            DispatchQueue.main.async {
                completion(true)
            }
        }.resume()
    }
    
    func fetchSongsForVoting(completion: @escaping ([Track]) -> Void) {
        guard let userId = UserDefaults.standard.value(forKey: "UserId") as? Int,
              let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            print("Error: userId or roomId not found in UserDefaults")
            completion([])
            return
        }
        let url = URL(string: "http://localhost:8080/songs/for-voting?roomId=\(roomId)&userId=\(userId)")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching songs: \(error)")
                completion([])
                return
            }
            guard let data = data else {
                print("No data received for songs")
                completion([])
                return
            }
            do {
                let decodedSongs = try JSONDecoder().decode([Track].self, from: data)
                completion(decodedSongs)
            } catch {
                print("Error decoding songs: \(error)")
                completion([])
            }
        }.resume()
    }
    
    func fetchCurrentRoundForRoom(roomId: Int, completion: @escaping ([Track]) -> Void) {
        let url = URL(string: "http://localhost:8080/currentRound?roomId=\(roomId)")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching current round: \(error)")
                completion([])
                return
            }
            guard let data = data else {
                print("No data received for current round")
                completion([])
                return
            }
            do {
                let decodedTracks = try JSONDecoder().decode([Track].self, from: data)
                completion(decodedTracks)
            } catch {
                print("Error decoding current round tracks: \(error)")
                completion([])
            }
        }.resume()
    }
    
    func awardBetsForWinner(winningSongId: Int, roomId: Int, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "http://localhost:8080/award-bets?roomId=\(roomId)&songId=\(winningSongId)")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error awarding bets: \(error)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server error or invalid response")
                completion(false)
                return
            }
            
            DispatchQueue.main.async {
                completion(true)
            }
        }.resume()
    }
    
    func fetchBetsForVoting(completion: @escaping ([Bet]) -> Void) {
        guard let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            print("Error: roomId not found in UserDefaults")
            completion([])
            return
        }
        
        let url = URL(string: "http://localhost:8080/bets/for-voting?roomId=\(roomId)")!
        print("Fetching bets for room: \(roomId) from: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching bets: \(error)")
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received for bets")
                completion([])
                return
            }
            
            do {
                let decodedBets = try JSONDecoder().decode([Bet].self, from: data)
                print("Fetched bets: \(decodedBets)")
                completion(decodedBets)
            } catch {
                print("Error decoding bets: \(error)")
                completion([])
            }
        }.resume()
    }
    
    func determineWinner(votes: [Int: Int], bets: [Bet]) -> Int? {
        var totalBetForSong1 = 0
        var totalBetForSong2 = 0
        
        print("Determining winner with votes: \(votes) and bets: \(bets)")
        
        for bet in bets {
            if bet.songId == votes[1] {
                totalBetForSong1 += bet.betAmount
            }
            else if bet.songId == votes[2] {
                totalBetForSong2 += bet.betAmount
            }
        }
        
        print("Total bet for song 1: \(totalBetForSong1), Total bet for song 2: \(totalBetForSong2)")
        
        if totalBetForSong1 > totalBetForSong2 {
            print("Song 1 wins")
            return votes[1]
        } else if totalBetForSong2 > totalBetForSong1 {
            print("Song 2 wins")
            return votes[2]
        }
        
        print("It's a tie, choosing randomly")
        return votes.randomElement()?.value
    }
    
    func sendVote(songId: Int, completion: @escaping (Bool) -> Void) {
        guard let userId = UserDefaults.standard.value(forKey: "UserId") as? Int else {
            print("Error: userId not found in UserDefaults")
            completion(false)
            return
        }
        
        guard let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            print("Error: roomId not found in UserDefaults")
            completion(false)
            return
        }
        
        let url = URL(string: "http://localhost:8080/vote/submit")!
        print("Sending vote for songId: \(songId) from userId: \(userId) in roomId: \(roomId) to: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let body: [String: Any] = [
            "songId": songId,
            "userId": userId,
            "roomId": roomId
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error submitting vote: \(error)")
                completion(false)
                return
            }
            print("Vote submitted successfully")
            completion(true)
        }.resume()
    }
    
    func getTotalBetsForSong(songId: Int, completion: @escaping (Int) -> Void) {
        guard let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            print("Error: roomId not found in UserDefaults")
            completion(0)
            return
        }
        
        let url = URL(string: "http://localhost:8080/bets/for-song?roomId=\(roomId)&songId=\(songId)")!
        print("Fetching total bets for songId: \(songId) in roomId: \(roomId) from: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching bets: \(error)")
                completion(0)
                return
            }
            
            guard let data = data else {
                completion(0)
                return
            }
            
            do {
                let bets: [Bet] = try JSONDecoder().decode([Bet].self, from: data)
                let totalBetAmount = bets.reduce(0) { $0 + $1.betAmount }
                print("Total bets for songId \(songId): \(totalBetAmount)")
                completion(totalBetAmount)
            } catch {
                print("Error decoding bets: \(error)")
                completion(0)
            }
        }.resume()
    }
    
    func checkIfAllVotesAreSubmitted(roomId: Int, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "http://localhost:8080/bets/all-submitted?roomId=\(roomId)")!
        print("Checking if all votes are submitted for roomId: \(roomId) from: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error checking if all votes are submitted: \(error)")
                completion(false)
                return
            }
            
            guard let data = data else {
                completion(false)
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode([String: Bool].self, from: data)
                if let allSubmitted = decodedResponse["allSubmitted"] {
                    print("All votes submitted: \(allSubmitted)")
                    completion(allSubmitted)
                } else {
                    completion(false)
                }
            } catch {
                print("Error decoding response: \(error)")
                completion(false)
            }
        }.resume()
    }
}
