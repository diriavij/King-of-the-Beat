//
//  BetsPresenter.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 08.04.2025.
//

import Foundation

final class BetsPresenter: BetsPresentationLogic {
    // MARK: - View
    weak var view: BetsViewController?

    // MARK: - Methods
    func routeToVotingScreen(_ response: BetsModels.RouteToVoting.Response) {
        let votingVC = VotingAssembly.build()
        votingVC.modalTransitionStyle = .coverVertical
        votingVC.modalPresentationStyle = .overFullScreen
        view?.present(votingVC, animated: true)
    }
}
