//
//  BetsInteractor.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 08.04.2025.
//

import Foundation

final class BetsInteractor: BetsBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: BetsPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: BetsPresentationLogic) {
        self.presenter = presenter
    }
}
