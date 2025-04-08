import Foundation
import UIKit

final class RoomCreationViewController: UIViewController {
    
    // MARK: - Variables and Constants
    private var interactor: RoomCreationBusinessLogic
    
    internal let lowerShining = UIImageView()
    
    private let createButton = UIButton(type: .system)
    private let returnButton = UIButton(type: .system)
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let inputContainer = UIView()
    let textField = UITextField()
    let gorgeousLabel = UILabel()
    
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
        navigationItem.hidesBackButton = true
        configureUI()
    }
    
    // MARK: - Configuring Methods
    
    private func configureUI() {
        view.backgroundColor = .black
        configureShining()
        configureReturnButton()
        configureNameField()
        configureCreationButton()
    }
    
    private func configureReturnButton() {
        view.addSubview(returnButton)
        let img = UIImage(named: "logo")
        returnButton.setImage(img, for: .normal)
        returnButton.tintColor = UIColor.convertToRGBInit("90A679")
        returnButton.pinLeft(to: view.leadingAnchor, 30)
        returnButton.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 30)
        returnButton.setHeight(50)
        returnButton.setWidth(50)
        returnButton.addTarget(self, action: #selector(didTapReturnButton), for: .touchUpInside)
    }
    
    private func configureNameField() {
        containerView.backgroundColor = UIColor.convertToRGBInit("5A7149")
        containerView.layer.cornerRadius = 40
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        containerView.pinCenterX(to: view)
        containerView.pinWidth(to: view.widthAnchor, 0.8)
        containerView.pinTop(to: returnButton.bottomAnchor, 150)
        containerView.setHeight(160)

        gorgeousLabel.text = "Room Creation"
        gorgeousLabel.textAlignment = .center
        gorgeousLabel.font = UIFont(name: "Modak", size: 48)
        gorgeousLabel.textColor = UIColor.convertToRGBInit("90A679")
        view.addSubview(gorgeousLabel)

        gorgeousLabel.pinBottom(to: containerView.topAnchor, 15)
        gorgeousLabel.pinCenterX(to: containerView.centerXAnchor)

        titleLabel.text = "Enter Room's\n Name:"
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        titleLabel.pinTop(to: gorgeousLabel.bottomAnchor, 15)
        titleLabel.pinCenterX(to: containerView)

        inputContainer.backgroundColor = UIColor.convertToRGBInit("90A679")
        inputContainer.layer.cornerRadius = 20
        inputContainer.clipsToBounds = true
        containerView.addSubview(inputContainer)

        inputContainer.pinTop(to: titleLabel.bottomAnchor, 15)
        inputContainer.pinCenterX(to: containerView)
        inputContainer.pinWidth(to: containerView.widthAnchor, 0.9)
        inputContainer.setHeight(50)

        textField.placeholder = "Enter name"
        textField.textAlignment = .left
        textField.textColor = .black
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.backgroundColor = .clear
        inputContainer.addSubview(textField)

        textField.pinLeft(to: inputContainer.leadingAnchor, 10)
        textField.pinRight(to: inputContainer.trailingAnchor, -10)
        textField.pinTop(to: inputContainer.topAnchor, 5)
        textField.pinBottom(to: inputContainer.bottomAnchor, -5)
    }
    
    private func configureCreationButton() {
        view.addSubview(createButton)
        createButton.setTitle("CREATE", for: .normal)
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        createButton.setTitleColor(.black, for: .normal)
        createButton.layer.cornerRadius = 25
        createButton.pinHeight(to: view.heightAnchor, 0.06)
        createButton.pinWidth(to: view.widthAnchor, 0.7)
        createButton.pinTop(to: containerView.bottomAnchor, 30)
        createButton.pinCenterX(to: view)
        createButton.backgroundColor = UIColor.convertToRGBInit("90A679")
        createButton.addTarget(self, action: #selector(didTapCreationButton), for: .touchUpInside)
    }
    
    private func configureShining() {
        lowerShining.image = UIImage(named: "shining_bottom")
        view.addSubview(lowerShining)
        lowerShining.pinBottom(to: view.bottomAnchor)
        lowerShining.pinCenterX(to: view)
        lowerShining.pinWidth(to: view)
        lowerShining.pinHeight(to: view, 0.5)
    }
    
    // MARK: - Actions
    
    @objc
    private func didTapReturnButton() {
        interactor.loadMainScreen(RoomCreationModels.RouteToMain.Request())
    }
    
    @objc
    private func didTapCreationButton() {
        interactor.createRoom(RoomCreationModels.CreateRoom.Request(name: textField.text ?? "Room"))
    }
}
