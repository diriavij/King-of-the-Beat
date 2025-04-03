//
//  MainPresenter.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.01.2025.
//

import Foundation
import UIKit

final class MainPresenter: MainPresentationLogic {
    
    // MARK: - View
    weak var view: MainViewController?
    
    
    // MARK: - Methods
    func routeToCreationScreen(_ response: MainModels.RouteToCreation.Response) {
        let creationVC = RoomCreationAssembly.build()
        let navController = UINavigationController(rootViewController: creationVC)
        navController.modalPresentationStyle = .overFullScreen
        navController.modalTransitionStyle = .coverVertical
        view?.present(navController, animated: true)
    }
    
    func routeToRoomScreen(_ response: MainModels.RouteToRoom.Response) {
        let creationVC = RoomAssembly.build()
        let navController = UINavigationController(rootViewController: creationVC)
        navController.modalPresentationStyle = .overFullScreen
        navController.modalTransitionStyle = .coverVertical
        view?.present(navController, animated: true)
    }
}
