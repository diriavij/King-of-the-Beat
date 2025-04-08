import Foundation

final class BetsPresenter: BetsPresentationLogic {
    // MARK: - View
    weak var view: BetsViewController?
    
    // MARK: - Methods
    func routeToVotingScreen(_ response: BetsModels.RouteToVoting.Response) {
        let votingVC = VotingAssembly.build()
        votingVC.modalTransitionStyle = .coverVertical
        votingVC.modalPresentationStyle = .overFullScreen
        if let nav = view?.navigationController {
            nav.pushViewController(votingVC, animated: true)
        }
    }
}
