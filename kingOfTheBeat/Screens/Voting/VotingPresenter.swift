import Foundation

final class VotingPresenter: VotingPresentationLogic {
    // MARK: - View
    weak var view: VotingViewController?
    
    func routeToResultsScreen(_ response: VotingModels.RouteToResults.Response) {
        let resultVC = ResultsAssembly.build()
        resultVC.modalTransitionStyle = .coverVertical
        resultVC.modalPresentationStyle = .overFullScreen
        if let nav = view?.navigationController {
          nav.pushViewController(resultVC, animated: true)
        }
    }
}
