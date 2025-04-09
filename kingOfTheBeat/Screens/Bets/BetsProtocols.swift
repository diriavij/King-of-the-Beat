//
//  BetsProtocols.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 08.04.2025.
//

import Foundation

protocol BetsBusinessLogic {
    func loadVotingScreen(_ request: BetsModels.RouteToVoting.Request)
}

protocol BetsPresentationLogic {
    func routeToVotingScreen(_ response: BetsModels.RouteToVoting.Response)
}
