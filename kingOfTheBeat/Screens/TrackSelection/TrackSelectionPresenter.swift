import Foundation
import UIKit

final class TrackSelectionPresenter: TrackSelectionPresentationLogic {
    
    // MARK: - View
    weak var view: TrackSelectionViewController?
    
    // MARK: - Methods
    func routeToBetsScreen(_ response: TrackSelectionModels.RouteToBets.Response) {
        let betsVC = BetsAssembly.build()
        betsVC.modalTransitionStyle = .coverVertical
        betsVC.modalPresentationStyle = .overFullScreen
        if let nav = view?.navigationController {
            nav.pushViewController(betsVC, animated: true)
        }
    }
}
