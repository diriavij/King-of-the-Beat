//
//  Room.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.02.2025.
//

import Foundation

struct Room: Codable {
    let roomId: Int
    let name: String
    let ownerId: Int
    let topic: String?
}
