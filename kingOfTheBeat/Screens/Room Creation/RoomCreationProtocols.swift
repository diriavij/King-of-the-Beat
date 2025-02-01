//
//  RoomCreationProtocols.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 02.01.2025.
//

import Foundation

protocol RoomCreationBusinessLogic {
    func loadMainScreen(_ request: RoomCreationModels.RouteToMain.Request)
    func createRoom(_ request: RoomCreationModels.CreateRoom.Request)
}

protocol RoomCreationPresentationLogic {
    func routeToMainScreen(_ response: RoomCreationModels.RouteToMain.Response)
    func routeToRoomScreen(_ response: RoomCreationModels.CreateRoom.Response)
}
