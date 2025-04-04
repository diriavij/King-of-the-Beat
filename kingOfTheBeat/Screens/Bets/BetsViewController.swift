//
//  BetsViewController.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 08.04.2025.
//

import Foundation
import UIKit

final class BetsViewController: UIViewController {
    
    private var interactor: BetsBusinessLogic
    
    init(interactor: BetsInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
    }
}
