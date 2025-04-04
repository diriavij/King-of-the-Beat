//
//  TrackSelectionAssembly.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 03.04.2025.
//

import Foundation

final class TrackSelectionAssembly {
    static func build(topic: String) -> TrackSelectionViewController {
        let presenter = TrackSelectionPresenter()
        let interactor = TrackSelectionInteractor(presenter: presenter)
        let view = TrackSelectionViewController(interactor: interactor, topic: topic)
        presenter.view = view
        return view
    }
}
