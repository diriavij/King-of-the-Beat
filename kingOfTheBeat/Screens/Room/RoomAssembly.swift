//
//  RoomAssembly.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.02.2025.
//

import Foundation

final class RoomAssembly {
    static func build() -> RoomViewController {
        var presenter = RoomPresenter()
        var interactor = RoomInteractor(presenter: presenter)
        var view = RoomViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
