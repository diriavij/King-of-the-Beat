import Foundation

final class ResultsAssembly {
    static func build() -> ResultsViewController {
        let presenter = ResultsPresenter()
        let interactor = ResultsInteractor(presenter: presenter)
        let vc = ResultsViewController(interactor: interactor)
        presenter.view = vc
        return vc
    }
}
