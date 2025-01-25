//
//  MainProtocols.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.01.2025.
//

import Foundation

protocol MainBusinessLogic {
    func loadCreationScreen(_ request: MainModels.RouteToCreation.Request)
}

protocol MainPresentationLogic {
    func routeToCreationScreen(_ response: MainModels.RouteToCreation.Response)
}
