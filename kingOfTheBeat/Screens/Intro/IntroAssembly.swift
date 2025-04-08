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
