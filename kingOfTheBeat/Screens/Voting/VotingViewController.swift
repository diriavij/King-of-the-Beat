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

        
        view.addSubview(upperShining)
        view.addSubview(lowerShining)

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
        
        // Timer label styling
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
            
            print("Fetched songs for voting: \(songs)")
            
            if songs.isEmpty {
                print("Error: No songs received for voting.")
            } else {
                self.songs = songs
                self.startVoting()
            }
        }
    }
    
    private func startVoting() {
        DispatchQueue.main.async {
            self.nextRound()
            self.startTimer()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        countdown = 30
        timerLabel.text = "\(countdown)"
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @objc
    private func updateTimer() {
        countdown -= 1
        DispatchQueue.main.async {
            self.timerLabel.text = "\(self.countdown)"
        }
        if countdown == 0 {
            timer?.invalidate()
            if votedSongIndex == nil {
                nextRound()
            }
        }
    }
    
    private func nextRound() {
        if songs.count > 1 {
            let firstSong = songs.randomElement()!
            var secondSong: Track
            repeat {
                secondSong = songs.randomElement()!
            } while firstSong.songId == secondSong.songId

            currentRound = [firstSong, secondSong]
            
            DispatchQueue.main.async {
                self.song1Label.setTitle("\(firstSong.artistName) - \(firstSong.trackName)", for: .normal)
                self.song2Label.setTitle("\(secondSong.artistName) - \(secondSong.trackName)", for: .normal)
                self.song1Label.isEnabled = true
                self.song2Label.isEnabled = true
                self.votedSongIndex = nil
            }
        } else {
            DispatchQueue.main.async {
                self.timerLabel.text = "Winner: \(self.songs.first?.trackName ?? "No Winner")"
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
    
    private func sendVote(songIndex: Int) {
        let song = currentRound[songIndex]
        interactor.sendVote(songId: song.songId) { success in
            if success {
                self.nextRound()
            } else {
                self.showAlert("Error sending vote")
            }
        }
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
