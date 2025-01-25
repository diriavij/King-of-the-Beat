//
//  RoomCreationViewController.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 02.01.2025.
//

import Foundation
import UIKit

final class RoomCreationViewController: UIViewController {
    
    // MARK: - Variables and Constants
    private var interactor: RoomCreationBusinessLogic
    
    // MARK: - Lifecycle
    init(interactor: RoomCreationInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }
}
