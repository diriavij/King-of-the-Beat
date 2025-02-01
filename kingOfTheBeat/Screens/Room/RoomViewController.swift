//
//  RoomViewController.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 01.02.2025.
//

import Foundation
import UIKit

final class RoomViewController: UIViewController {
    
    private var interactor: RoomBusinessLogic
    
    // MARK: - Lifecycle
    init(interactor: RoomInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
