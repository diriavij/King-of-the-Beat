//
//  Room.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.02.2025.
//

import Foundation

struct Room: Encodable {
    var roomId: Int
    var ownerId: Int
    var name: String
}
