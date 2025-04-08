//
//  RoomProtocols.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.02.2025.
//

import Foundation

protocol RoomBusinessLogic {
    func routeToTrackSelection(_ request: RoomModels.RouteToTrackSelection.Request)
}

protocol RoomPresentationLogic {
    func presentTrackSelection(_ response: RoomModels.RouteToTrackSelection.Response)
}
