//
//  RoomCreationInteractor.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 02.01.2025.
//

import Foundation

final class RoomCreationInteractor: RoomCreationBusinessLogic {
    
    // MARK: - Presenter
    private var presenter: RoomCreationPresentationLogic
    
    // MARK: - Lifecycle
    init(presenter: RoomCreationPresentationLogic) {
        self.presenter = presenter
    }

}

