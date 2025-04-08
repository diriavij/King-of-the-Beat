import Foundation
import UIKit

final class VotingViewController: UIViewController {
    
    private let timerLabel = UILabel()
    private let song1Button = UIButton(type: .system)
    private let song2Button = UIButton(type: .system)
    private let timerBackground = UIView()
    private let upperShining = UIImageView()
    private let lowerShining = UIImageView()
    private let vsLabel = UILabel()
    private var waitingAlert: UIAlertController?
    
    private var timer: Timer?
    private var countdown = 30
    private var currentRound: [Track] = []
    
    private let interactor: VotingInteractor
    
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
        navigationItem.hidesBackButton = true
        setupUI()
        resetVotes()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nextRound()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        upperShining.image = UIImage(named: "shining_top")
        lowerShining.image = UIImage(named: "shining_bottom")
        [upperShining, lowerShining].forEach { iv in
            iv.contentMode = .scaleAspectFill
            view.addSubview(iv)
            iv.translatesAutoresizingMaskIntoConstraints = false
        }
        upperShining.pinTop(to: view.topAnchor)
        upperShining.pinCenterX(to: view)
        upperShining.pinWidth(to: view)
        upperShining.pinHeight(to: view, 0.5)
        lowerShining.pinBottom(to: view.bottomAnchor)
        lowerShining.pinCenterX(to: view)
        lowerShining.pinWidth(to: view)
        lowerShining.pinHeight(to: view, 0.5)
        
        timerBackground.backgroundColor = UIColor.convertToRGBInit("90A679")
        timerBackground.layer.cornerRadius = 30
        view.addSubview(timerBackground)
        view.addSubview(timerLabel)
        [timerBackground, timerLabel].forEach { v in v.translatesAutoresizingMaskIntoConstraints = false }
        timerLabel.font = .systemFont(ofSize: 32, weight: .bold)
        timerLabel.textColor = .black
        timerLabel.textAlignment = .center
        
        [song1Button, song2Button].forEach { btn in
            btn.isEnabled = false
            btn.setTitle("Loading...", for: .normal)
            btn.setTitleColor(UIColor.convertToRGBInit("90A679"), for: .normal)
            btn.titleLabel?.font = UIFont(name: "Modak", size: 24)
            view.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
        }
        song1Button.addTarget(self, action: #selector(voteForSong1), for: .touchUpInside)
        song2Button.addTarget(self, action: #selector(voteForSong2), for: .touchUpInside)
        
        vsLabel.text = "VS"
        vsLabel.font = UIFont(name: "Modak", size: 80)
        vsLabel.textColor = UIColor.convertToRGBInit("90A679")
        vsLabel.textAlignment = .center
        view.addSubview(vsLabel)
        vsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            timerBackground.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            timerBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            timerBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            timerBackground.heightAnchor.constraint(equalToConstant: 60),
            timerLabel.centerXAnchor.constraint(equalTo: timerBackground.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerBackground.centerYAnchor),
            
            song1Button.topAnchor.constraint(equalTo: timerBackground.bottomAnchor, constant: 100),
            song1Button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            vsLabel.topAnchor.constraint(equalTo: song1Button.bottomAnchor, constant: 10),
            vsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            song2Button.topAnchor.constraint(equalTo: vsLabel.bottomAnchor, constant: 10),
            song2Button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func resetVotes() {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        interactor.resetVotesForRoom(roomId: roomId) { success in
            if !success {
                print("Failed to reset votes for room \(roomId)")
            }
        }
    }
    
    private func nextRound() {
        resetVotes()
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        print("Fetching current round for room \(roomId)")
        interactor.fetchCurrentRoundForRoom(roomId: roomId) { [weak self] tracks in
            guard let self = self else { return }
            DispatchQueue.main.async {
                print("Received tracks: \(tracks)")
                if tracks.count != 2 {
                    self.timerLabel.text = "Winner: \(tracks.first?.trackName ?? "No Winner")"
                    return
                }
                self.currentRound = tracks
                self.song1Button.setTitle("\(tracks[0].artistName) - \(tracks[0].trackName)", for: .normal)
                self.song2Button.setTitle("\(tracks[1].artistName) - \(tracks[1].trackName)", for: .normal)
                self.song1Button.isEnabled = true
                self.song2Button.isEnabled = true
                self.startTimer()
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
        timerLabel.text = "\(countdown)"
        if countdown <= 0 {
            timer?.invalidate()
            let choice = arc4random_uniform(2)
            if choice == 0 { voteForSong1() } else { voteForSong2() }
        }
    }
    
    @objc private func voteForSong1() { submitVote(at: 0) }
    @objc private func voteForSong2() { submitVote(at: 1) }
    
    private func submitVote(at index: Int) {
        guard currentRound.indices.contains(index) else { return }
        song1Button.isEnabled = false
        song2Button.isEnabled = false
        showWaitingAlert()
        let songId = currentRound[index].songId
        interactor.sendVote(songId: songId) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.waitForVotesOrAdvance()
            } else {
                self.showAlert("Error sending vote")
            }
        }
    }
    
    private func waitForVotesOrAdvance() {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        interactor.checkIfAllVotesAreSubmitted(roomId: roomId) { [weak self] all in
            guard let self = self else { return }
            if all {
                self.hideWaitingAlert()
                self.advanceRound()
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.waitForVotesOrAdvance()
                }
            }
        }
    }
    
    private func advanceRound() {
        let roomId = UserDefaults.standard.integer(forKey: "Room")
        interactor.advanceRound(roomId: roomId) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.nextRound()
                } else {
                    self?.interactor.loadResultsScreen(VotingModels.RouteToResults.Request())
                }
            }
        }
    }
    
    private func showWaitingAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Waiting for others...", message: nil, preferredStyle: .alert)
            self.present(alert, animated: true)
            self.waitingAlert = alert
        }
    }

    private func hideWaitingAlert() {
        DispatchQueue.main.async {
            self.waitingAlert?.dismiss(animated: true)
            self.waitingAlert = nil
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
