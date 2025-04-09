//
//  VotingInteractor.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 09.04.2025.
//

import Foundation

final class VotingInteractor: VotingBusinessLogic {
    // MARK: - Presenter
    private var presenter: VotingPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: VotingPresentationLogic) {
        self.presenter = presenter
    }
    
    func fetchSongsForVoting(completion: @escaping ([Track]) -> Void) {
        guard let userId = UserDefaults.standard.value(forKey: "UserId") as? Int,
              let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            print("Error: userId or roomId not found in UserDefaults")
            return
        }
        let url = URL(string: "http://localhost:8080/songs/for-voting?roomId=\(roomId)&userId=\(userId)")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching songs:", error)
                completion([])
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion([])
                return
            }
            
            do {
                let decodedSongs = try JSONDecoder().decode([Track].self, from: data)
                completion(decodedSongs)
            } catch {
                print("Error decoding songs:", error)
                completion([])
            }
        }.resume()
    }
    
    func sendVote(songId: Int, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "http://localhost:8080/vote")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let body: [String: Any] = ["songId": songId, "userId": 1]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error submitting vote:", error)
                completion(false)
                return
            }
            
            completion(true)
        }.resume()
    }
}
