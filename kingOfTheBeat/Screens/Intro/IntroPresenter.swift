import UIKit
import WebKit

class IntroPresenter: IntroPresentationLogic {
   
    // MARK: - View
    weak var view: IntroViewController?
    
    // MARK: - Methods
    
    func presentAuth(_ response: IntroModels.Auth.Response) {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view?.view.frame.size.width ?? 0, height: view?.view.frame.size.height ?? 0))
        let newController = UIViewController()
        
        webView.load(response.response)
        webView.navigationDelegate = view
        newController.view.addSubview(webView)
        view?.present(newController, animated: true)
        view?.authWebView = newController
    }
    
    func routeToMain(_ response: IntroModels.Route.Response) {
        let mainVC = MainAssembly.build()
        let navController = UINavigationController(rootViewController: mainVC)
        navController.modalPresentationStyle = .overFullScreen
        navController.modalTransitionStyle = .coverVertical
        view?.present(navController, animated: true)
    }
}
