//
//  IntroAssembly.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 25.11.2024.
//

import Foundation

// MARK: - IntroAssembly
class IntroAssembly {
    static func build() -> IntroViewController {
        let presenter = IntroPresenter()
        let interactor = IntroInteractor(presenter: presenter)
        let view = IntroViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
