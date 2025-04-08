import Foundation

enum APIConstants {
    static let apiBaseUrl = "https://api.spotify.com"
    static let authBaseUrl = "https://accounts.spotify.com"
    static let authHost = "accounts.spotify.com"
    static let clientId = "7f7bc9847c29420196d4ec342fb49076"
    static let clientSecret = "c2e085365404445789f876bf044c99f9"
    static let redirectUri = "https://www.google.com"
    static let responseType = "code"
    static let scopes = "user-read-private playlist-modify-private playlist-modify-public"
    
    static var authParams = [
        "response_type": responseType,
        "client_id": clientId,
        "scope": scopes,
        "redirect_uri": redirectUri
    ]
}
