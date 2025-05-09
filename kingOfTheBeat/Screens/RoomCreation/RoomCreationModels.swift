import Foundation

enum RoomCreationModels {
    enum RouteToMain {
        struct Request {}
        struct Response {}
        struct ViewModel {}
    }
    
    enum CreateRoom {
        struct Request {
            var name: String
        }
        struct Response {
            var name: String
        }
        struct ViewModel {}
    }
}
