import Foundation

final class BetsInteractor: BetsBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: BetsPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: BetsPresentationLogic) {
        self.presenter = presenter
    }
    
    // MARK: - Methods
    
    func loadVotingScreen(_ request: BetsModels.RouteToVoting.Request) {
        presenter.routeToVotingScreen(BetsModels.RouteToVoting.Response())
    }
}
