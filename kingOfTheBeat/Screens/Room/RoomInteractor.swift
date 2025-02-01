//
//  RoomInteractor.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.02.2025.
//

import Foundation

class RoomInteractor: RoomBusinessLogic {
    private var presenter: RoomPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: RoomPresentationLogic) {
        self.presenter = presenter
    }
}
