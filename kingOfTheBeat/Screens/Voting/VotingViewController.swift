//
//  VotingViewController.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 09.04.2025.
//

import Foundation
import UIKit

final class VotingViewController: UIViewController {
    private var interactor: VotingInteractor

    init(interactor: VotingInteractor) {
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
