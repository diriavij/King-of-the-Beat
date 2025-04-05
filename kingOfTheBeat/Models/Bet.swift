//
//  Bet.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 10.04.2025.
//

import Foundation

struct Bet: Codable {
    let userId: Int
    let songId: Int
    let betAmount: Int
}
