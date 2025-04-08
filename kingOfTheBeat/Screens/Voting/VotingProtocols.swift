import Foundation

protocol VotingBusinessLogic {
    func fetchSongsForVoting(completion: @escaping ([Track]) -> Void)
    func sendVote(songId: Int, completion: @escaping (Bool) -> Void)
    
    func loadResultsScreen(_ request: VotingModels.RouteToResults.Request)
}

protocol VotingPresentationLogic {
    func routeToResultsScreen(_ response: VotingModels.RouteToResults.Response)
}
