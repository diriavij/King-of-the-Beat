//
//  SpotifyTrack.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 03.04.2025.
//

import Foundation

struct SpotifyTrack: Codable {
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    var id: String
}
