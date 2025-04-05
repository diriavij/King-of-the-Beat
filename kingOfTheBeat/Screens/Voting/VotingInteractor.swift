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
}
