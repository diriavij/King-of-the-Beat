import Foundation

class RoomInteractor: RoomBusinessLogic {
    
    private var presenter: RoomPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: RoomPresentationLogic) {
        self.presenter = presenter
    }
    
    func routeToTrackSelection(_ request: RoomModels.RouteToTrackSelection.Request) {
        DispatchQueue.main.async {
            self.presenter.presentTrackSelection(RoomModels.RouteToTrackSelection.Response(topic: request.topic))
        }
    }
    
}
