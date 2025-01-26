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
    
    internal let lowerShining = UIImageView()
    
    private let createButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let inputContainer = UIView()
    let textField = UITextField()
    let sendButton = UIButton(type: .system)
    
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
        configureUI()
    }
    
    // MARK: - Configuring Methods
    
    private func configureUI() {
        view.backgroundColor = .black
        configureShining()
        configureCreationButton()
        configureSettingsButton()
        configureJoin()
    }
    
    private func configureSettingsButton() {
        view.addSubview(settingsButton)
        let img = UIImage(named: "logo")
        settingsButton.setImage(img, for: .normal)
        settingsButton.tintColor = UIColor.convertToRGBInit("90A679")
        settingsButton.pinLeft(to: view.leadingAnchor, 30)
        settingsButton.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 30)
        settingsButton.setHeight(50)
        settingsButton.setWidth(50)
    }
    
    private func configureJoin() {
        containerView.backgroundColor = UIColor.convertToRGBInit("5A7149")
        containerView.layer.cornerRadius = 40
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        containerView.pinTop(to: createButton.bottomAnchor, 20)
        containerView.pinCenterX(to: view)
        containerView.pinWidth(to: view.widthAnchor, 0.7)
        containerView.setHeight(170)
        
        titleLabel.text = "Join Room\nvia Code:"
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: UIFont.Weight(2))
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
        
        titleLabel.pinTop(to: containerView.topAnchor, 10)
        titleLabel.pinCenterX(to: containerView)
        
        inputContainer.backgroundColor = UIColor.convertToRGBInit("90A679")
        inputContainer.layer.cornerRadius = 25
        inputContainer.clipsToBounds = true
        containerView.addSubview(inputContainer)
        
        inputContainer.pinTop(to: titleLabel.bottomAnchor, 20)
        inputContainer.pinCenterX(to: containerView)
        inputContainer.pinWidth(to: containerView.widthAnchor, 0.9)
        inputContainer.setHeight(50)
        
        textField.placeholder = "Enter code"
        textField.autocapitalizationType = UITextAutocapitalizationType.allCharacters
        textField.textAlignment = .center
        textField.textColor = .black
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.backgroundColor = .clear
        inputContainer.addSubview(textField)
        //textField.addTarget(self, action: #selector(codeChanged), for: .editingChanged)
        
        textField.pinLeft(to: inputContainer.leadingAnchor, 10)
        textField.pinTop(to: inputContainer.topAnchor, 5)
        textField.pinBottom(to: inputContainer.bottomAnchor, 5)
        
        let arrowImage = UIImage(systemName: "arrow.right")
        sendButton.setImage(arrowImage, for: .normal)
        sendButton.tintColor = .black
        inputContainer.addSubview(sendButton)
        
        sendButton.pinRight(to: inputContainer.trailingAnchor, 10)
        sendButton.pinCenterY(to: inputContainer)
        sendButton.setWidth(20)
        sendButton.setHeight(20)
        
        //sendButton.addTarget(self, action: #selector(didTapJoinRoom), for: .touchUpInside)
    }
    
    private func configureCreationButton() {
        view.addSubview(createButton)
        createButton.setTitle("Create Room", for: .normal)
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 36, weight: UIFont.Weight(5))
        createButton.setTitleColor(.black, for: .normal)
        createButton.layer.cornerRadius = 25
        createButton.pinHeight(to: view.heightAnchor, 0.06)
        createButton.pinWidth(to: view.widthAnchor, 0.7)
        createButton.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 200)
        createButton.pinCenterX(to: view)
        createButton.backgroundColor = UIColor.convertToRGBInit("90A679")
        //createButton.addTarget(self, action: #selector(didTapCreationButton), for: .touchUpInside)
    }
    
    private func configureShining() {
        lowerShining.image = UIImage(named: "shining_bottom")
        view.addSubview(lowerShining)
        lowerShining.pinBottom(to: view.bottomAnchor)
        lowerShining.pinCenterX(to: view)
        lowerShining.pinWidth(to: view)
        lowerShining.pinHeight(to: view, 0.5)
    }
    
}
