import UIKit
import Foundation

final class ResultsViewController: UIViewController {
    private let interactor: ResultsBusinessLogic
    private var topThree: [Track] = []
    private var allSongs: [Track] = []
    
    let gorgeousLabel = UILabel()
    private let firstPodium = UIView()
    private let secondPodium = UIView()
    private let thirdPodium = UIView()
    
    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private let thirdLabel = UILabel()
    
    private let playlistButton = UIButton(type: .system)
    private let exitButton = UIButton(type: .system)
    
    init(interactor: ResultsBusinessLogic) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        navigationItem.hidesBackButton = true
        setupUI()
        loadResults()
    }
    
    private func setupUI() {
        gorgeousLabel.textAlignment = .center
        gorgeousLabel.font = UIFont(name: "Modak", size: 32)
        gorgeousLabel.textColor = UIColor.convertToRGBInit("90A679")
        gorgeousLabel.text = "RESULTS"
        view.addSubview(gorgeousLabel)

        gorgeousLabel.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 50)
        gorgeousLabel.pinCenterX(to: view.centerXAnchor)
        
        secondPodium.backgroundColor = UIColor.convertToRGBInit("809F60")
        firstPodium.backgroundColor  = UIColor.convertToRGBInit("5A7149")
        thirdPodium.backgroundColor  = UIColor.convertToRGBInit("2D3D23")
        
        [secondPodium, firstPodium, thirdPodium].forEach { bar in
            bar.layer.cornerRadius = 12
            view.addSubview(bar)
            bar.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [firstLabel, secondLabel, thirdLabel].forEach { label in
            label.textColor = .black
            label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            label.numberOfLines = 1
            label.textAlignment = .center
            label.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
            view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
        }
        
        playlistButton.setTitle("Add Playlist to Spotify", for: .normal)
        exitButton.setTitle("Exit", for: .normal)
        [playlistButton, exitButton].forEach { btn in
            btn.backgroundColor = UIColor.convertToRGBInit("90A679")
            btn.setTitleColor(.black, for: .normal)
            btn.layer.cornerRadius = 20
            view.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
        }
        playlistButton.addTarget(self, action: #selector(didTapPlaylist), for: .touchUpInside)
        exitButton.addTarget(self, action: #selector(didTapExit), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            secondPodium.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            secondPodium.widthAnchor.constraint(equalToConstant: 60),
            secondPodium.bottomAnchor.constraint(equalTo: playlistButton.topAnchor, constant: -40),
            secondPodium.heightAnchor.constraint(equalToConstant: 320),
            
            firstPodium.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            firstPodium.widthAnchor.constraint(equalToConstant: 60),
            firstPodium.bottomAnchor.constraint(equalTo: playlistButton.topAnchor, constant: -40),
            firstPodium.heightAnchor.constraint(equalToConstant: 380),
            
            thirdPodium.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            thirdPodium.widthAnchor.constraint(equalToConstant: 60),
            thirdPodium.bottomAnchor.constraint(equalTo: playlistButton.topAnchor, constant: -40),
            thirdPodium.heightAnchor.constraint(equalToConstant: 260),
            
            secondLabel.centerXAnchor.constraint(equalTo: secondPodium.centerXAnchor),
            secondLabel.centerYAnchor.constraint(equalTo: secondPodium.centerYAnchor),
            firstLabel.centerXAnchor.constraint(equalTo: firstPodium.centerXAnchor),
            firstLabel.centerYAnchor.constraint(equalTo: firstPodium.centerYAnchor),
            thirdLabel.centerXAnchor.constraint(equalTo: thirdPodium.centerXAnchor),
            thirdLabel.centerYAnchor.constraint(equalTo: thirdPodium.centerYAnchor),
            
            playlistButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            playlistButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            playlistButton.bottomAnchor.constraint(equalTo: exitButton.topAnchor, constant: -16),
            playlistButton.heightAnchor.constraint(equalToConstant: 50),
            
            exitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            exitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            exitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            exitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func loadResults() {
        interactor.fetchTopThree { [weak self] tracks in
            guard let self = self, tracks.count == 3 else { return }
            self.topThree = tracks
            
            DispatchQueue.main.async {
                self.firstLabel.text  = "\(tracks[0].artistName) - \(tracks[0].trackName)"
                self.secondLabel.text = "\(tracks[1].artistName) - \(tracks[1].trackName)"
                self.thirdLabel.text  = "\(tracks[2].artistName) - \(tracks[2].trackName)"
            }
        }
        interactor.fetchAllSongs { [weak self] songs in
            self?.allSongs = songs
        }
    }
    
    @objc private func didTapPlaylist() {
        guard let token = UserDefaults.standard.string(forKey: "Authorization"),
              !allSongs.isEmpty else {
            showAlert("No songs or not authorized"); return
        }
        
        let roomName = UserDefaults.standard.string(forKey: "RoomName") ?? "My Room"
        let group = DispatchGroup()
        var uris = [String]()
        
        for track in allSongs {
            group.enter()
            let query = "\(track.trackName) \(track.artistName)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let url = URL(string: "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=1")!
            var req = URLRequest(url: url)
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: req) { data, _, _ in
                defer { group.leave() }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                      let items = (json["tracks"] as? [String:Any])?["items"] as? [[String:Any]],
                      let uri = items.first?["uri"] as? String else {
                    print("URI not found for", track.trackName)
                    return
                }
                uris.append(uri)
            }.resume()
        }
        
        group.notify(queue: .main) {
            guard !uris.isEmpty else {
                self.showAlert("No URIs found")
                return
            }
            self.createSpotifyPlaylistDirectly(roomName: roomName, uris: uris, token: token)
        }
    }
    
    private func createSpotifyPlaylistDirectly(roomName: String, uris: [String], token: String) {
        let createURL = URL(string: "https://api.spotify.com/v1/me/playlists")!
        var createReq = URLRequest(url: createURL)
        createReq.httpMethod = "POST"
        createReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String:Any] = [
            "name": roomName,
            "description": "Playlist from room \"\(roomName)\"",
            "public": false
        ]
        createReq.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: createReq) { data, response, error in
            if let error = error {
                print("Spotify create playlist error:", error)
                DispatchQueue.main.async { self.showAlert("Failed to create playlist") }
                return
            }
            guard let http = response as? HTTPURLResponse,
                  let data = data else {
                print("Spotify no response/data for playlist creation")
                DispatchQueue.main.async { self.showAlert("Failed to create playlist") }
                return
            }
            print("Spotify createPlaylist HTTP \(http.statusCode), body:", String(data: data, encoding: .utf8) ?? "")
            guard (200...299).contains(http.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
                  let playlistId = json["id"] as? String else {
                DispatchQueue.main.async { self.showAlert("Failed to create playlist") }
                return
            }
            
            let addURL = URL(string: "https://api.spotify.com/v1/playlists/\(playlistId)/tracks")!
            var addReq = URLRequest(url: addURL)
            addReq.httpMethod = "POST"
            addReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            addReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let tracksBody = ["uris": uris]
            addReq.httpBody = try? JSONSerialization.data(withJSONObject: tracksBody, options: [])
            
            URLSession.shared.dataTask(with: addReq) { data2, response2, error2 in
                if let error2 = error2 {
                    print("Spotify add tracks error:", error2)
                    DispatchQueue.main.async { self.showAlert("Failed to add tracks") }
                    return
                }
                guard let http2 = response2 as? HTTPURLResponse,
                      let data2 = data2 else {
                    print("Spotify no response/data when adding tracks")
                    DispatchQueue.main.async { self.showAlert("Failed to add tracks") }
                    return
                }
                print("Spotify addTracks HTTP \(http2.statusCode), body:", String(data: data2, encoding: .utf8) ?? "")
                DispatchQueue.main.async {
                    let success = (200...299).contains(http2.statusCode)
                    self.showAlert(success ? "Playlist added!" : "Failed to add tracks")
                }
            }.resume()
            
        }.resume()
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func didTapExit() {
        navigationController?.popToRootViewController(animated: true)
    }
}
