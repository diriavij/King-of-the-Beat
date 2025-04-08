import Foundation

protocol IntroBusinessLogic {
    func getAuthToken(_ request: IntroModels.Auth.Request)
    func loadMain(_ request: IntroModels.Route.Request)
}

protocol IntroPresentationLogic {
    func presentAuth(_ response: IntroModels.Auth.Response)
    func routeToMain(_ response: IntroModels.Route.Response)
}
