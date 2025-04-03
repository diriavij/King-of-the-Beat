//
//  MainProtocols.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.01.2025.
//

import Foundation

protocol MainBusinessLogic {
    func loadCreationScreen(_ request: MainModels.RouteToCreation.Request)
    func loadRoomScreen(_ request: MainModels.RouteToRoom.Request)
    func joinRoom(with code: Int, userId: Int, completion: @escaping (Bool) -> Void)
}

protocol MainPresentationLogic {
    func routeToCreationScreen(_ response: MainModels.RouteToCreation.Response)
    func routeToRoomScreen(_ response: MainModels.RouteToRoom.Response)
}
