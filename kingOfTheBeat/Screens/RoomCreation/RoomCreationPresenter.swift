import Foundation
import UIKit

final class RoomCreationPresenter: RoomCreationPresentationLogic {
    
    // MARK: - View
    weak var view: RoomCreationViewController?
    
    // MARK: - Methods
    
    func routeToMainScreen(_ response: RoomCreationModels.RouteToMain.Response) {
        view?.navigationController?.popToRootViewController(animated: true)
    }
    
    func routeToRoomScreen(_ response: RoomCreationModels.CreateRoom.Response) {
        let creationVC = RoomAssembly.build()
        creationVC.modalTransitionStyle = .coverVertical
        creationVC.modalPresentationStyle = .overFullScreen
        if let nav = view?.navigationController {
            nav.pushViewController(creationVC, animated: true)
        }
    }
}
