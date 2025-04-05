import Foundation
import UIKit

final class VotingViewController: UIViewController {
    
    private let timerLabel = UILabel()
    private let song1Label = UIButton(type: .system)
    private let song2Label = UIButton(type: .system)
    private let timerBackground = UIView()
    private let upperShining = UIImageView()
    private let lowerShining = UIImageView()
    private let vsLabel = UILabel()
    
    private var timer: Timer?
    private var countdown = 30
    private var songs: [Track] = []
    private var currentRound: [Track] = []
    private var votedSongIndex: Int?
    private var userVotes: [Int: Int] = [:]
    
    private var interactor: VotingInteractor
    
    private var isWaitingForVotes = false
    
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
        resetVotes()
        setupUI()
        fetchSongs()
        startVoting()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        upperShining.image = UIImage(named: "shining_top")
        view.addSubview(upperShining)
        upperShining.pinTop(to: view.topAnchor)
        upperShining.pinCenterX(to: view)
        upperShining.pinWidth(to: view)
        upperShining.pinHeight(to: view, 0.5)
        
        lowerShining.image = UIImage(named: "shining_bottom")
        view.addSubview(lowerShining)
        lowerShining.pinBottom(to: view.bottomAnchor)
        lowerShining.pinCenterX(to: view)
        lowerShining.pinWidth(to: view)
        lowerShining.pinHeight(to: view, 0.5)
        
        timerBackground.backgroundColor = UIColor.convertToRGBInit("90A679")
        timerBackground.layer.cornerRadius = 30
        view.addSubview(timerBackground)
        view.addSubview(timerLabel)
        view.addSubview(song1Label)
        view.addSubview(song2Label)
        view.addSubview(vsLabel)
        
        timerBackground.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        song1Label.translatesAutoresizingMaskIntoConstraints = false
        song2Label.translatesAutoresizingMaskIntoConstraints = false
        vsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        timerLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        timerLabel.textColor = .black
        timerLabel.textAlignment = .center
        
        song1Label.setTitleColor(UIColor.convertToRGBInit("90A679"), for: .normal)
        song1Label.titleLabel?.font = UIFont(name: "Modak", size: 24)
        song1Label.addTarget(self, action: #selector(voteForSong1), for: .touchUpInside)
        
        song2Label.setTitleColor(UIColor.convertToRGBInit("90A679"), for: .normal)
        song2Label.titleLabel?.font = UIFont(name: "Modak", size: 24)
        song2Label.addTarget(self, action: #selector(voteForSong2), for: .touchUpInside)
        
        vsLabel.text = "VS"
        vsLabel.font = UIFont(name: "Modak", size: 80)
        vsLabel.textColor = UIColor.convertToRGBInit("90A679")
        vsLabel.textAlignment = .center
        
        NSLayoutConstraint.activate([
            timerBackground.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            timerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            timerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            timerBackground.heightAnchor.constraint(equalToConstant: 60),
            
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerBackground.centerYAnchor),
            
            song1Label.topAnchor.constraint(equalTo: timerBackground.bottomAnchor, constant: 100),
            song1Label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            vsLabel.topAnchor.constraint(equalTo: song1Label.bottomAnchor, constant: 10),
            vsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            song2Label.topAnchor.constraint(equalTo: vsLabel.bottomAnchor, constant: 10),
            song2Label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func fetchSongs() {
        interactor.fetchSongsForVoting { [weak self] songs in
            guard let self = self else { return }
            
            if songs.isEmpty {
                self.showAlert("Error: No songs received for voting.")
            } else {
                self.songs = songs
                self.startVoting()
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        countdown = 30
        timerLabel.text = "\(countdown)"
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
    }
    
    @objc private func updateTimer() {
        countdown -= 1
        DispatchQueue.main.async {
            self.timerLabel.text = "\(self.countdown)"
        }
        if countdown == 0 {
            let randomChoice = arc4random_uniform(2)
            if randomChoice == 0 {
                voteForSong1()
            } else {
                voteForSong2()
            }
        }
    }
    
    private func startVoting() {
        DispatchQueue.main.async {
            self.nextRound()
            self.startTimer()
        }
    }
    
    private func nextRound() {
        guard let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            print("Error: roomId not found in UserDefaults")
            return
        }

        interactor.fetchCurrentRoundForRoom(roomId: roomId) { [weak self] songs in
            guard let self = self else { return }

            if songs.count == 2 {
                self.currentRound = songs
                DispatchQueue.main.async {
                    self.resetVotes()
                    self.song1Label.setTitle("\(songs[0].artistName) - \(songs[0].trackName)", for: .normal)
                    self.song2Label.setTitle("\(songs[1].artistName) - \(songs[1].trackName)", for: .normal)
                    self.song1Label.isEnabled = true
                    self.song2Label.isEnabled = true
                    self.votedSongIndex = nil
                    self.startTimer()
                }
            } else {
                DispatchQueue.main.async {
                    self.timerLabel.text = "Winner: \(songs.first?.trackName ?? "No Winner")"
                }
            }
        }
    }
    
    private func checkAllVotesSubmitted() {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        
        guard let url = URL(string: "http://localhost:8080/room/all-submitted?roomId=\(roomId)") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error checking votes:", error)
                return
            }
            
            guard let data = data,
                  let response = try? JSONDecoder().decode([String: Bool].self, from: data),
                  let allVotesSubmitted = response["allSubmitted"] else {
                return
            }
            
            if allVotesSubmitted {
                DispatchQueue.main.async {
                    self.determineWinnerAndNextRound()
                }
            }
        }.resume()
    }
    
    private func waitForOthers() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Waiting for others...", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true)
            
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
                self.checkAllVotesSubmitted()
                if self.isWaitingForVotes == false {
                    timer.invalidate()
                    DispatchQueue.main.async {
                        alert.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    private func resetVotes() {
        guard let roomId = UserDefaults.standard.value(forKey: "Room") as? Int else {
            print("Error: roomId not found in UserDefaults")
            return
        }
        interactor.resetVotesForRoom(roomId: roomId) { success in
            if success {
                print("All votes were successfully reset for room \(roomId).")
            } else {
                print("Failed to reset votes for room \(roomId).")
            }
        }
    }
    
    private func sendVote(songIndex: Int) {
        let song = currentRound[songIndex]
        interactor.sendVote(songId: song.songId) { success in
            if success {
                self.votedSongIndex = songIndex
                self.checkVotes()
            } else {
                self.showAlert("Error sending vote")
            }
        }
    }
    
    private func checkVotes() {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        interactor.checkIfAllVotesAreSubmitted(roomId: roomId) { allVoted in
            if allVoted {
                self.determineWinnerAndNextRound()
            } else {
                self.waitForOthers()
            }
        }
    }
    
    @objc
    private func voteForSong1() {
        votedSongIndex = 0
        song1Label.isEnabled = false
        song2Label.isEnabled = false
        sendVote(songIndex: 0)
    }
    
    @objc
    private func voteForSong2() {
        votedSongIndex = 1
        song1Label.isEnabled = false
        song2Label.isEnabled = false
        sendVote(songIndex: 1)
    }
    
    private func determineWinnerAndNextRound() {
        interactor.getTotalBetsForSong(songId: currentRound[0].songId) { song1Bets in
            self.interactor.getTotalBetsForSong(songId: self.currentRound[1].songId) { song2Bets in
                if song1Bets > song2Bets {
                    self.songs.removeAll { $0.songId == self.currentRound[1].songId }
                } else if song2Bets > song1Bets {
                    self.songs.removeAll { $0.songId == self.currentRound[0].songId }
                } else {
                    if Int.random(in: 0...1) == 0 {
                        self.songs.removeAll { $0.songId == self.currentRound[1].songId }
                    } else {
                        self.songs.removeAll { $0.songId == self.currentRound[0].songId }
                    }
                }
                self.nextRound()
            }
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
