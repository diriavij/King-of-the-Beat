//
//  TrackSelectionInteractor.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 03.04.2025.
//

import Foundation

final class TrackSelectionInteractor: TrackSelectionBusinessLogic {
    // MARK: - Presenter
    private var presenter: TrackSelectionPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: TrackSelectionPresentationLogic) {
        self.presenter = presenter
    }
}
