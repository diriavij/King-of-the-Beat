import Foundation
import UIKit

final class MainPresenter: MainPresentationLogic {
    
    // MARK: - View
    weak var view: MainViewController?
    
    
    // MARK: - Methods
    func routeToCreationScreen(_ response: MainModels.RouteToCreation.Response) {
        let creationVC = RoomCreationAssembly.build()
        creationVC.modalTransitionStyle = .coverVertical
        creationVC.modalPresentationStyle = .overFullScreen
        if let nav = view?.navigationController {
            nav.pushViewController(creationVC, animated: true)
        }
    }
    
    func routeToRoomScreen(_ response: MainModels.RouteToRoom.Response) {
        let creationVC = RoomAssembly.build()
        creationVC.modalTransitionStyle = .coverVertical
        creationVC.modalPresentationStyle = .overFullScreen
        if let nav = view?.navigationController {
            nav.pushViewController(creationVC, animated: true)
        }
    }
}
