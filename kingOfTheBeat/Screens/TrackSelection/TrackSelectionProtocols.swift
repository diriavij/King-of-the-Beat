//
//  TrackSelectionProtocols.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 03.04.2025.
//

import Foundation

protocol TrackSelectionBusinessLogic {
    func loadBetsScreen(_ request: TrackSelectionModels.RouteToBets.Request)
}

protocol TrackSelectionPresentationLogic {
    func routeToBetsScreen(_ response: TrackSelectionModels.RouteToBets.Response)
}
