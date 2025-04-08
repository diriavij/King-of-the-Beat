import Foundation
import UIKit

final class RoomPresenter: RoomPresentationLogic {
    
    var view: RoomViewController?
    
    func presentTrackSelection(_ response: RoomModels.RouteToTrackSelection.Response) {
        let vc = TrackSelectionAssembly.build(topic: response.topic)
        vc.modalTransitionStyle = .coverVertical
        vc.modalPresentationStyle = .overFullScreen
        if let nav = view?.navigationController {
            nav.pushViewController(vc, animated: true)
        }
    }
}
