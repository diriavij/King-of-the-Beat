//
//  RoomCreationAssembly.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 02.01.2025.
//

import Foundation

final class RoomCreationAssembly {
    static func build() -> RoomCreationViewController {
        let presenter = RoomCreationPresenter()
        let interactor = RoomCreationInteractor(presenter: presenter)
        let view = RoomCreationViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
