//
//  Room.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.02.2025.
//

import Foundation

struct Room: Encodable, Decodable {
    var roomId: Int
    var name: String
    var ownerId: Int
}
