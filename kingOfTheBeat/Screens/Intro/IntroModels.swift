import Foundation

enum IntroModels {
    enum Auth {
        struct Request {}
        struct Response {
            var response: URLRequest
        }
        struct ViewModel {}
    }
    
    enum Route {
        struct Request {}
        struct Response {}
        struct ViewModel {}
    }
}
