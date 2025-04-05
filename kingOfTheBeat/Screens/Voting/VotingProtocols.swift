//
//  VotingProtocols.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 09.04.2025.
//

import Foundation

protocol VotingBusinessLogic {
    func fetchSongsForVoting(completion: @escaping ([Track]) -> Void)
    func sendVote(songId: Int, completion: @escaping (Bool) -> Void)
}

protocol VotingPresentationLogic {
    
}
