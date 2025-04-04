//
//  TrackSelectionPresenter.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 03.04.2025.
//

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
        view?.present(betsVC, animated: true)
    }
}
