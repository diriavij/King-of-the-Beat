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
