import UIKit

final class BetsViewController: UIViewController {
    
    private let balanceLabel = UILabel()
    private let betsTitle = UILabel()
    private let stackView = UIStackView()
    private let nextButton = UIButton(type: .system)
    
    private var songs: [Track] = []
    private var bets: [Int] = []
    private var userBalance: Int = 0
    
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
        view.backgroundColor = .black
        navigationItem.hidesBackButton = true
        fetchData()
    }
    
    private func fetchData() {
        let userId = UserDefaults.standard.integer(forKey: "UserId")
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        
        fetchBalance(for: userId) { balance in
            self.userBalance = balance
            
            self.fetchSongs(for: roomId) { songs in
                self.songs = songs
                self.bets = Array(repeating: 0, count: songs.count)
                
                DispatchQueue.main.async {
                    print("Fetched songs:", self.songs)
                    self.setupBalance()
                    self.setupTitle()
                    self.setupBets()
                    self.setupNextButton()
                }
            }
        }
    }
    
    private func fetchBalance(for userId: Int, completion: @escaping (Int) -> Void) {
        guard let url = URL(string: "http://localhost:8080/user/balance?userId=\(userId)") else {
            completion(0); return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let response = try? JSONDecoder().decode([String: Int].self, from: data),
                  let balance = response["balance"] else {
                completion(0)
                return
            }
            completion(balance)
        }.resume()
    }
    
    private func fetchSongs(for roomId: Int, completion: @escaping ([Track]) -> Void) {
        let userId = UserDefaults.standard.integer(forKey: "UserId")
        guard let url = URL(string: "http://localhost:8080/room/random-songs?roomId=\(roomId)&userId=\(userId)") else {
            print("Invalid URL or missing parameters")
            completion([]); return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching songs:", error)
                completion([]); return
            }
            
            guard let data = data else {
                print("No data received")
                completion([]); return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            
            do {
                let decoded = try JSONDecoder().decode([Track].self, from: data)
                print("Decoded songs:", decoded)
                completion(decoded)
            } catch {
                print("Error decoding songs:", error)
                completion([]); return
            }
        }.resume()
    }
    
    private func setupBalance() {
        balanceLabel.text = "Your Balance: \(userBalance)"
        balanceLabel.textColor = UIColor.convertToRGBInit("90A679")
        balanceLabel.textAlignment = .center
        balanceLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        
        view.addSubview(balanceLabel)
        balanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            balanceLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            balanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupTitle() {
        betsTitle.text = "BETS"
        betsTitle.font = UIFont(name: "Modak", size: 40)
        betsTitle.textColor = UIColor.convertToRGBInit("90A679")
        betsTitle.textAlignment = .center
        
        view.addSubview(betsTitle)
        betsTitle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            betsTitle.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 16),
            betsTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupBets() {
        stackView.axis = .vertical
        stackView.spacing = 24
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: betsTitle.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
        
        if songs.isEmpty {
            print("No songs available to display")
            return
        }
        
        for (index, song) in songs.enumerated() {
            let row = createBetRow(for: song, at: index)
            stackView.addArrangedSubview(row)
        }
    }
    
    private func createBetRow(for song: Track, at index: Int) -> UIStackView {
        let nameLabel = UILabel()
        nameLabel.text = "\(song.artistName) - \(song.trackName)"
        nameLabel.textColor = UIColor.convertToRGBInit("90A679")
        nameLabel.font = UIFont.systemFont(ofSize: 24)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        let downButton = UIButton(type: .system)
        downButton.setTitle("▼", for: .normal)
        downButton.setTitleColor(UIColor.convertToRGBInit("90A679"), for: .normal)
        downButton.tag = index
        downButton.addTarget(self, action: #selector(decreaseBet(_:)), for: .touchUpInside)
        
        let upButton = UIButton(type: .system)
        upButton.setTitle("▲", for: .normal)
        upButton.setTitleColor(UIColor.convertToRGBInit("90A679"), for: .normal)
        upButton.tag = index
        upButton.addTarget(self, action: #selector(increaseBet(_:)), for: .touchUpInside)
        
        let betLabel = UILabel()
        betLabel.text = "0"
        betLabel.textColor = UIColor.convertToRGBInit("90A679")
        betLabel.textAlignment = .center
        betLabel.tag = 100 + index
        betLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        let betBox = UIStackView(arrangedSubviews: [downButton, betLabel, upButton])
        betBox.axis = .horizontal
        betBox.backgroundColor = UIColor.convertToRGBInit("1C2616")
        betBox.layer.cornerRadius = 24
        betBox.spacing = 20
        betBox.distribution = .equalCentering
        betBox.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        betBox.isLayoutMarginsRelativeArrangement = true
        
        let fullRow = UIStackView(arrangedSubviews: [nameLabel, betBox])
        fullRow.axis = .vertical
        fullRow.spacing = 8
        
        return fullRow
    }
    
    @objc private func increaseBet(_ sender: UIButton) {
        let index = sender.tag
        if userBalance > 0 {
            bets[index] += 100
            userBalance -= 100
            updateUI(for: index)
        }
    }
    
    @objc private func decreaseBet(_ sender: UIButton) {
        let index = sender.tag
        if bets[index] >= 100 {
            bets[index] -= 100
            userBalance += 100
            updateUI(for: index)
        }
    }
    
    private func updateUI(for index: Int) {
        if let betLabel = view.viewWithTag(100 + index) as? UILabel {
            betLabel.text = "\(bets[index])"
        }
        balanceLabel.text = "Your Balance: \(userBalance)"
    }
    
    private func setupNextButton() {
        nextButton.setTitle("NEXT", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        nextButton.setTitleColor(.black, for: .normal)
        nextButton.backgroundColor = UIColor.convertToRGBInit("90A679")
        nextButton.layer.cornerRadius = 24
        view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.addTarget(self, action: #selector(handleNext), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 200),
            nextButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    
    @objc private func handleNext() {
        sendBetsToServer { [weak self] success in
            guard let self = self, success else {
                self?.showAlert("Failed to submit bets.")
                return
            }
            self.waitForOthers()
        }
    }
    
    private func fetchSongsForBets(for roomId: Int, completion: @escaping ([Track]) -> Void) {
        let userId = UserDefaults.standard.integer(forKey: "UserId")
        guard let url = URL(string: "http://localhost:8080/room/random-songs?roomId=\(roomId)&userId=\(userId)") else {
            print("Invalid URL or missing parameters")
            completion([]); return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching songs:", error)
                completion([]); return
            }

            guard let data = data else {
                print("No data received")
                completion([]); return
            }

            do {
                let decoded = try JSONDecoder().decode([Track].self, from: data)
                print("Decoded songs:", decoded)
                completion(decoded)
            } catch {
                print("Error decoding songs:", error)
                completion([]); return
            }
        }.resume()
    }

    private func sendBetsToServer(completion: @escaping (Bool) -> Void) {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        let userId = UserDefaults.standard.integer(forKey: "UserId")

        fetchSongsForBets(for: roomId) { songs in
            let betsData = self.bets.enumerated().map { index, bet in
                return [
                    "betAmount": bet,
                    "songId": self.songs[index].songId
                ]
            }

            let payload: [String: Any] = [
                "roomId": roomId,
                "userId": userId,
                "bets": betsData
            ]

            guard let url = URL(string: "http://localhost:8080/bets/submit"),
                  let body = try? JSONSerialization.data(withJSONObject: payload) else {
                completion(false)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request) { _, _, error in
                if let error = error {
                    print("Error submitting bets:", error)
                    completion(false)
                    return
                }
                completion(true)
            }.resume()
        }
    }

    private func waitForOthers() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Waiting for others...", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true)

            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
                self.checkAllBetsSubmitted { allReady in
                    if allReady {
                        timer.invalidate()
                        DispatchQueue.main.async {
                            alert.dismiss(animated: true)
                            self.interactor.loadVotingScreen(BetsModels.RouteToVoting.Request())
                        }
                    }
                }
            }
        }
    }

    private func checkAllBetsSubmitted(completion: @escaping (Bool) -> Void) {
        let roomId = UserDefaults.standard.integer(forKey: "Room")

        guard let url = URL(string: "http://localhost:8080/bets/all-submitted?roomId=\(roomId)") else {
            completion(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error checking bets:", error)
                completion(false)
                return
            }

            guard let data = data,
                  let response = try? JSONDecoder().decode([String: Bool].self, from: data),
                  let allBetsSubmitted = response["allBetsSubmitted"] else {
                completion(false)
                return
            }

            completion(allBetsSubmitted)
        }.resume()
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
