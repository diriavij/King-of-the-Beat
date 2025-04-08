import Foundation

protocol BetsBusinessLogic {
    func loadVotingScreen(_ request: BetsModels.RouteToVoting.Request)
}

protocol BetsPresentationLogic {
    func routeToVotingScreen(_ response: BetsModels.RouteToVoting.Response)
}
