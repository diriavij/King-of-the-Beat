//
//  RoomPresenter.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.02.2025.
//

import Foundation
import UIKit

final class RoomPresenter: RoomPresentationLogic {
    
    var view: RoomViewController?
    
    func presentTrackSelection(_ response: RoomModels.RouteToTrackSelection.Response) {
        let vc = TrackSelectionAssembly.build(topic: response.topic)
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .overFullScreen
        navController.modalTransitionStyle = .coverVertical
        view?.present(navController, animated: true)
    }
}
