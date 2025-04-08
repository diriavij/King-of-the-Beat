import Foundation

final class TrackSelectionInteractor: TrackSelectionBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: TrackSelectionPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: TrackSelectionPresentationLogic) {
        self.presenter = presenter
    }
    
    // MARK: - Methods
    func loadBetsScreen(_ request: TrackSelectionModels.RouteToBets.Request) {
        presenter.routeToBetsScreen(TrackSelectionModels.RouteToBets.Response())
    }
}
