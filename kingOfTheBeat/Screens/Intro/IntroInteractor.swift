//
//  IntroInteractor.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.01.2025.
//

import Foundation

// MARK: - IntroInteractor
class IntroInteractor: IntroBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: IntroPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: IntroPresentationLogic) {
        self.presenter = presenter
    }
    
    // MARK: - Methods
    
    func getAuthToken(_ request: IntroModels.Auth.Request) {
        let helper = APIService()
        guard let response = helper.getAccessTokenUrl() else { return }
        presenter.presentAuth(IntroModels.Auth.Response(response: response))
    }
    
    func loadMain(_ request: IntroModels.Route.Request) {
        presenter.routeToMain(IntroModels.Route.Response())
    }
}
