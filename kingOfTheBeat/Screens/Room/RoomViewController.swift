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
    
    var tableView: UITableView = UITableView(frame: .zero)
    private var webSocketManager = WebSocketManager()
    private var participants: [User] = []
    
    internal let lowerShining = UIImageView()
    
    private let returnButton = UIButton(type: .system)
    
    let containerView = UIView()
    let titleLabel = UILabel()
    let code = UILabel()
    let gorgeousLabel = UILabel()
    let participantsLabel = UILabel()
    let startButton = UIButton(type: .system)
    
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
        configureUI()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ParticipantCell.self, forCellReuseIdentifier: "ParticipantCell")

        webSocketManager.connect()
        NotificationCenter.default.addObserver(self, selector: #selector(updateParticipants), name: .participantsUpdated, object: nil)

        fetchParticipants()
    }
    
    deinit {
        webSocketManager.disconnect()
    }
    
    // MARK: - Configuring Methods
    private func configureUI() {
        view.backgroundColor = .black
        configureReturnButton()
        configureStartButton()
        configureCode()
        configureRoomName()
        configureTable()
    }
    
    private func configureTable() {
        view.addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.pinTop(to: participantsLabel.bottomAnchor, 20)
    }
    
    private func configureRoomName() {
        getRoomInfo { [weak self] roomName in
            DispatchQueue.main.async {
                self?.gorgeousLabel.text = roomName
            }
        }
        gorgeousLabel.textAlignment = .center
        gorgeousLabel.font = UIFont(name: "Modak", size: 32)
        gorgeousLabel.textColor = UIColor.convertToRGBInit("90A679")
        view.addSubview(gorgeousLabel)

        gorgeousLabel.pinTop(to: returnButton.bottomAnchor, 20)
        gorgeousLabel.pinCenterX(to: view.centerXAnchor)
        
        participantsLabel.text = "Participants"
        participantsLabel.textAlignment = .center
        participantsLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        participantsLabel.textColor = UIColor.convertToRGBInit("5A7149")
        view.addSubview(participantsLabel)

        participantsLabel.pinTop(to: gorgeousLabel.bottomAnchor, 10)
        participantsLabel.pinCenterX(to: view.centerXAnchor)
    }
    
    private func configureCode() {
        containerView.backgroundColor = UIColor.convertToRGBInit("90A679")
        containerView.layer.cornerRadius = 40
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        containerView.pinCenterX(to: view)
        containerView.pinWidth(to: view.widthAnchor, 0.8)
        containerView.pinBottom(to: startButton.topAnchor, 20)
        containerView.setHeight(120)

        titleLabel.text = "Room's code"
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        titleLabel.pinTop(to: containerView.topAnchor, 15)
        titleLabel.pinCenterX(to: containerView)

        code.text = String(UserDefaults.standard.integer(forKey: "Room"))
        code.font = UIFont.systemFont(ofSize: 32, weight: UIFont.Weight(5))
        code.textColor = .black
        code.textAlignment = .center
        containerView.addSubview(code)
        
        code.pinTop(to: titleLabel.bottomAnchor, 15)
        code.pinCenterX(to: containerView)
    }
    
    private func configureReturnButton() {
        view.addSubview(returnButton)
        let img = UIImage(named: "logo")
        returnButton.setImage(img, for: .normal)
        returnButton.tintColor = UIColor.convertToRGBInit("90A679")
        returnButton.pinLeft(to: view.leadingAnchor, 30)
        returnButton.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 20)
        returnButton.setHeight(50)
        returnButton.setWidth(50)
    }
    
    private func configureStartButton() {
        view.addSubview(startButton)
        startButton.setTitle("Start Game", for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        startButton.setTitleColor(.black, for: .normal)
        startButton.layer.cornerRadius = 25
        startButton.pinHeight(to: view.heightAnchor, 0.06)
        startButton.pinWidth(to: view.widthAnchor, 0.7)
        startButton.pinBottom(to: view.bottomAnchor, 100)
        startButton.pinCenterX(to: view)
        startButton.backgroundColor = UIColor.convertToRGBInit("5A7149")
    }
    
    private func fetchParticipants() {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        let urlString = "http://localhost:8080/room/participants?roomId=\(roomId)"
        
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки участников:", error.localizedDescription)
                return
            }

            guard let data = data else {
                print("Нет данных от сервера")
                return
            }

            do {
                let participants = try JSONDecoder().decode([User].self, from: data)
                DispatchQueue.main.async {
                    self.participants = participants
                    self.tableView.reloadData()
                }
            } catch {
                print("Ошибка декодирования JSON участников:", error)
            }
        }.resume()
    }
    
    // MARK: - Helper Methods
    
    private func getRoomInfo(completion: @escaping (String) -> Void) {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        let urlString = "http://localhost:8080/room/info?roomId=\(roomId)"
        
        guard let url = URL(string: urlString) else {
            completion("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Ошибка загрузки комнаты: \(error.localizedDescription)")
                DispatchQueue.main.async { completion("Error loading room") }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion("No data received") }
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("Полученный JSON: \(jsonString)")
            } else {
                print("Ошибка: не удалось преобразовать ответ в строку")
            }

            do {
                let roomInfo = try JSONDecoder().decode(Room.self, from: data)
                DispatchQueue.main.async { completion(roomInfo.name) }
            } catch {
                print("Ошибка декодирования JSON: \(error)")
                DispatchQueue.main.async { completion("Invalid response") }
            }
        }.resume()
    }
    
    @objc
    private func updateParticipants(notification: Notification) {
        guard let updatedParticipants = notification.object as? [User] else { return }
        DispatchQueue.main.async {
            self.participants = updatedParticipants
            self.tableView.reloadData()
        }
    }
}

extension RoomViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return participants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ParticipantCell", for: indexPath) as! ParticipantCell
        cell.configure(with: participants[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60  // Высота каждой строки
    }
}
