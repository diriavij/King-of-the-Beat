//
//  RoomCreationPresenter.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 02.01.2025.
//

import Foundation
import UIKit

final class RoomCreationPresenter: RoomCreationPresentationLogic {
    
    // MARK: - View
    weak var view: RoomCreationViewController?
    
    // MARK: - Methods
    
    func routeToMainScreen(_ response: RoomCreationModels.RouteToMain.Response) {
        view?.dismiss(animated: true)
    }
    
    func routeToRoomScreen(_ response: RoomCreationModels.CreateRoom.Response) {
        let creationVC = RoomAssembly.build()
        let navController = UINavigationController(rootViewController: creationVC)
        navController.modalPresentationStyle = .overFullScreen
        navController.modalTransitionStyle = .coverVertical
        view?.present(navController, animated: true)
    }
}
