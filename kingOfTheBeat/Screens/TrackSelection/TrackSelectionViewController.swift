//
//  TrackSelectionViewController.swift
//  kingOfTheBeat
//
//  Created by Фома Попов on 03.04.2025.
//

import UIKit

final class TrackSelectionViewController: UIViewController {

    private let topicTitle = UILabel()
    private let searchContainer = UIView()
    private let textField = UITextField()
    private let tableView = UITableView()
    private let addedSongsLabel = UILabel()
    private let addedSongsStack = UIStackView()
    private let nextButton = UIButton(type: .system)

    private var results: [SpotifyTrack] = []
    private var addedSongs: [SpotifyTrack] = []

    private var interactor: TrackSelectionInteractor
    private var topic: String

    init(interactor: TrackSelectionInteractor, topic: String) {
        self.interactor = interactor
        self.topic = topic
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureTopicTitle()
        configureSearchBox()
        configureSuggestionsTable()
        configureAddedSongsSection()
        configureNextButton()
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
    }

    private func configureTopicTitle() {
        topicTitle.text = "Topic: \(topic)"
        topicTitle.textColor = UIColor.convertToRGBInit("90A679")
        topicTitle.textAlignment = .center
        topicTitle.font = UIFont(name: "Modak", size: 52)
        view.addSubview(topicTitle)
        topicTitle.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topicTitle.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            topicTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func configureSearchBox() {
        searchContainer.backgroundColor = UIColor.convertToRGBInit("4B5A3D")
        searchContainer.layer.cornerRadius = 30
        view.addSubview(searchContainer)
        searchContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchContainer.topAnchor.constraint(equalTo: topicTitle.bottomAnchor, constant: 20),
            searchContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            searchContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])

        textField.placeholder = "Enter Song’s Name"
        textField.backgroundColor = UIColor.convertToRGBInit("90A679")
        textField.textAlignment = .center
        textField.layer.cornerRadius = 20
        textField.returnKeyType = .search
        textField.delegate = self
        searchContainer.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: searchContainer.topAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func configureSuggestionsTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 20
        tableView.clipsToBounds = true
        tableView.register(SpotifyTrackCell.self, forCellReuseIdentifier: "SpotifyTrackCell")
        searchContainer.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 180),
            tableView.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: -16)
        ])
    }

    private func configureAddedSongsSection() {
        addedSongsLabel.text = "Already Added"
        addedSongsLabel.textColor = UIColor.convertToRGBInit("90A679")
        addedSongsLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        addedSongsLabel.textAlignment = .center
        view.addSubview(addedSongsLabel)
        addedSongsLabel.translatesAutoresizingMaskIntoConstraints = false

        addedSongsStack.axis = .vertical
        addedSongsStack.spacing = 10
        addedSongsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addedSongsStack)

        NSLayoutConstraint.activate([
            addedSongsLabel.topAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: 10),
            addedSongsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addedSongsStack.topAnchor.constraint(equalTo: addedSongsLabel.bottomAnchor, constant: 10),
            addedSongsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            addedSongsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }

    private func configureNextButton() {
        nextButton.setTitle("NEXT", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        nextButton.setTitleColor(.black, for: .normal)
        nextButton.backgroundColor = UIColor.convertToRGBInit("90A679")
        nextButton.layer.cornerRadius = 24
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 200),
            nextButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func addSong(_ track: SpotifyTrack) {
        let maxSongs = 12 / max(1, participantsCount())
        guard addedSongs.count < maxSongs else {
            showAlert("You can only add \(maxSongs) songs.")
            return
        }

        guard !addedSongs.contains(where: { $0.id == track.id }) else { return }
        addedSongs.append(track)

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 40).isActive = true

        let albumImageView = UIImageView()
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.clipsToBounds = true
        albumImageView.layer.cornerRadius = 6
        albumImageView.translatesAutoresizingMaskIntoConstraints = false
        albumImageView.widthAnchor.constraint(equalToConstant: 35).isActive = true
        albumImageView.heightAnchor.constraint(equalToConstant: 35).isActive = true

        if let urlString = track.album.images.first?.url,
           let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    albumImageView.image = image
                }
            }.resume()
        } else {
            albumImageView.image = UIImage(systemName: "music.note")
        }

        let songLabel = UILabel()
        songLabel.text = "\(track.artists.first?.name ?? "") – \(track.name)"
        songLabel.textColor = .white
        songLabel.font = UIFont.systemFont(ofSize: 12)
        songLabel.numberOfLines = 2
        songLabel.textAlignment = .left

        let infoStack = UIStackView(arrangedSubviews: [albumImageView, songLabel])
        infoStack.axis = .horizontal
        infoStack.spacing = 10
        infoStack.alignment = .center

        let removeButton = UIButton(type: .system)
        removeButton.setTitle("✕", for: .normal)
        removeButton.setTitleColor(.white, for: .normal)
        removeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        removeButton.addTarget(self, action: #selector(handleRemove(_:)), for: .touchUpInside)
        removeButton.tag = addedSongs.count - 1
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.widthAnchor.constraint(equalToConstant: 30).isActive = true

        let hStack = UIStackView(arrangedSubviews: [infoStack, removeButton])
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center
        hStack.distribution = .equalSpacing
        hStack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: container.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        addedSongsStack.addArrangedSubview(container)
    }
    
    private func participantsCount() -> Int {
        return UserDefaults.standard.integer(forKey: "ParticipantsCount")
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc
    private func handleRemove(_ sender: UIButton) {
        let index = sender.tag
        guard index < addedSongs.count else { return }
        addedSongs.remove(at: index)
        addedSongsStack.arrangedSubviews[index].removeFromSuperview()

        for (i, view) in addedSongsStack.arrangedSubviews.enumerated() {
            if let stack = view as? UIStackView, let button = stack.arrangedSubviews.last as? UIButton {
                button.tag = i
            }
        }
    }

    private func searchSpotify(for query: String) {
        guard let token = UserDefaults.standard.string(forKey: "Authorization") else {
            print("Нет токена")
            return
        }

        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=track&limit=10") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Ошибка запроса:", error)
                return
            }

            guard let data = data else { return }

            do {
                let decoded = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
                DispatchQueue.main.async {
                    self.results = decoded.tracks.items
                    self.tableView.reloadData()
                }
            } catch {
                print("Ошибка декодирования:", error)
            }

        }.resume()
    }
    
    @objc private func handleNext() {
        sendSongsToServer { [weak self] success in
            guard let self = self, success else {
                self?.showAlert("Failed to submit songs.")
                return
            }
            markSubmissionComplete { success in
                guard success else {
                    self.showAlert("Could not notify submission completion.")
                    return
                }
                DispatchQueue.main.async {
                    self.waitForOthers()
                }
            }
        }
    }
    
    private func sendSongsToServer(completion: @escaping (Bool) -> Void) {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        let userId = UserDefaults.standard.integer(forKey: "UserId")

        let songs = addedSongs.map { song in
            return [
                "trackName": song.name,
                "artistName": song.artists.first?.name ?? "",
                "albumUrl": song.album.images.first?.url ?? ""
            ]
        }

        let payload: [String: Any] = [
            "roomId": roomId,
            "userId": userId,
            "songs": songs
        ]

        guard let url = URL(string: "http://localhost:8080/songs/submit"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error submitting songs:", error)
                completion(false)
                return
            }
            print("Отправляем песни:", songs)
            completion(true)
        }.resume()
    }
    
    private func markSubmissionComplete(completion: @escaping (Bool) -> Void) {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        let userId = UserDefaults.standard.integer(forKey: "UserId")

        guard let url = URL(string: "http://localhost:8080/room/submission-done?roomId=\(roomId)&userId=\(userId)") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "roomId": roomId,
            "userId": userId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error marking submission complete:", error)
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    private func waitForOthers() {
        let alert = UIAlertController(title: "Waiting for others...", message: nil, preferredStyle: .alert)
        present(alert, animated: true)

        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            self.checkAllSubmitted { allReady in
                if allReady {
                    timer.invalidate()
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true) {
                            self.interactor.loadBetsScreen(TrackSelectionModels.RouteToBets.Request())
                        }
                    }
                }
            }
        }
    }

    private func checkAllSubmitted(completion: @escaping (Bool) -> Void) {
        let roomId = UserDefaults.standard.integer(forKey: "Room")

        guard let url = URL(string: "http://localhost:8080/room/all-submitted?roomId=\(roomId)") else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error checking submissions:", error)
                completion(false)
                return
            }

            guard let data = data,
                  let response = try? JSONDecoder().decode([String: Bool].self, from: data),
                  let allSubmitted = response["allSubmitted"] else {
                completion(false)
                return
            }

            completion(allSubmitted)
        }.resume()
    }
    
}

extension TrackSelectionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let query = textField.text, !query.isEmpty {
            searchSpotify(for: query)
        }
        textField.resignFirstResponder()
        return true
    }
}

extension TrackSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let track = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SpotifyTrackCell", for: indexPath) as! SpotifyTrackCell
        cell.configure(with: track)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        addSong(results[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
