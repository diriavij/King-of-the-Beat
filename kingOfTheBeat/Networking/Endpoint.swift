import UIKit
protocol Endpoint {
    var compositePath: String {get}
    var headers: [String: String] {get}
    var parameters: [String: String]? {get}
}

extension Endpoint {
    var parameters: [String: String]? {return nil}
    
}
