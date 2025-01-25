//
//  MainInteractor.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.01.2025.
//

import Foundation

final class MainInteractor: MainBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: MainPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: MainPresentationLogic) {
        self.presenter = presenter
    }
    
    // MARK: - Methods
    func loadCreationScreen(_ request: MainModels.RouteToCreation.Request) {
        presenter.routeToCreationScreen(MainModels.RouteToCreation.Response())
    }
}
