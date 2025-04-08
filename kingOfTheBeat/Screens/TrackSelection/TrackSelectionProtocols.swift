import Foundation

protocol TrackSelectionBusinessLogic {
    func loadBetsScreen(_ request: TrackSelectionModels.RouteToBets.Request)
}

protocol TrackSelectionPresentationLogic {
    func routeToBetsScreen(_ response: TrackSelectionModels.RouteToBets.Response)
}
