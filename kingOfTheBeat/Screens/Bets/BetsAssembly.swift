import Foundation

final class BetsAssembly {
    static func build() -> BetsViewController {
        let presenter = BetsPresenter()
        let interactor = BetsInteractor(presenter: presenter)
        let view = BetsViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
