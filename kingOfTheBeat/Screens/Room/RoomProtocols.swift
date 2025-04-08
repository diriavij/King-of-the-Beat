import Foundation

protocol RoomBusinessLogic {
    func routeToTrackSelection(_ request: RoomModels.RouteToTrackSelection.Request)
}

protocol RoomPresentationLogic {
    func presentTrackSelection(_ response: RoomModels.RouteToTrackSelection.Response)
}
