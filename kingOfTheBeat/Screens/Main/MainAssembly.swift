//
//  MainAssembly.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.01.2025.
//

import Foundation

// MARK: - MainAssembly
class MainAssembly {
    static func build() -> MainViewController {
        let presenter = MainPresenter()
        let interactor = MainInteractor(presenter: presenter)
        let view = MainViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
