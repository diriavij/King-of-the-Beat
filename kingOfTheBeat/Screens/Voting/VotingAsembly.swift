//
//  VotingAsembly.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 09.04.2025.
//

import Foundation

final class VotingAssembly {
    static func build() -> VotingViewController {
        let presenter = VotingPresenter()
        let interactor = VotingInteractor(presenter: presenter)
        let vc = VotingViewController(interactor: interactor)
        presenter.view = vc
        return vc
    }
}
