//
//  User.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 25.01.2025.
//

import Foundation

struct User: Encodable, Decodable {
    var userId: Int
    var name: String
    var profilePic: String
}
