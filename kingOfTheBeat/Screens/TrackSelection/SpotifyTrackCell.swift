import UIKit

final class SpotifyTrackCell: UITableViewCell {

    private let albumImageView = UIImageView()
    private let songInfoLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with track: SpotifyTrack) {
        songInfoLabel.text = "\(track.artists.first?.name ?? "") – \(track.name)"
        
        if let urlString = track.album.images.first?.url,
           let url = URL(string: urlString) {
            loadImage(from: url)
        } else {
            albumImageView.image = UIImage(systemName: "music.note")
        }
    }

    private func setupUI() {
        backgroundColor = UIColor.convertToRGBInit("4B5A3D")
        layer.cornerRadius = 20
        clipsToBounds = true
        selectionStyle = .none

        // Album Image
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.clipsToBounds = true
        albumImageView.layer.cornerRadius = 8
        albumImageView.translatesAutoresizingMaskIntoConstraints = false
        albumImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        albumImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true

        // Song Info Label
        songInfoLabel.font = UIFont.systemFont(ofSize: 16)
        songInfoLabel.textColor = .white
        songInfoLabel.numberOfLines = 2
        songInfoLabel.translatesAutoresizingMaskIntoConstraints = false

        // Stack
        let stack = UIStackView(arrangedSubviews: [albumImageView, songInfoLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.albumImageView.image = image
            }
        }.resume()
    }
}
