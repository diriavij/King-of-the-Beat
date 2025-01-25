//
//  APIConstants.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 27.11.2024.
//

import Foundation

enum APIConstants {
    static let apiBaseUrl = "https://api.spotify.com"
    static let authBaseUrl = "https://accounts.spotify.com"
    static let authHost = "accounts.spotify.com"
    static let clientId = "7f7bc9847c29420196d4ec342fb49076"
    static let clientSecret = "c2e085365404445789f876bf044c99f9"
    static let redirectUri = "https://www.google.com"
    static let responseType = "code"
    static let scopes = "user-read-private"
    
    static var authParams = [
        "response_type": responseType,
        "client_id": clientId,
        "scopes": scopes,
        "redirect_uri": redirectUri
    ]
}
