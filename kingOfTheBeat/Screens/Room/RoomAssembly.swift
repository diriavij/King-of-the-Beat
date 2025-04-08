import Foundation

final class RoomAssembly {
    static func build() -> RoomViewController {
        let presenter = RoomPresenter()
        let interactor = RoomInteractor(presenter: presenter)
        let view = RoomViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
