import UIKit

final class ViewController: UIViewController {
    private var airPlayManager: AirPlayManager?
    private var nowPlayingManager: NowPlayingManager?
    private var bonjour: BonjourService?

    var hardwareAddress: [UInt8] {
        // Hard-code a random address to avoid the
        // convoluted lookup process
        return [184, 199, 93, 59, 114, 43]
    }

    private lazy var recordButtonView = UIView()..{
        $0.backgroundColor = UIColor.blue
        $0.makeCorner(withRadius: 20)
        $0.translatesAutoresizingMaskIntoConstraints = false

        let tap = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        tap.minimumPressDuration = 0
        tap.cancelsTouchesInView = false
        $0.addGestureRecognizer(tap)
    }

    @objc func handleTap(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            gesture.view?.animateButtonDown(scale: 0.9)
        } else if gesture.state == .ended {
            gesture.view?.animateButtonUp()

            nowPlayingManager?.togglePlayingState()
        }
    }

    let deleteImageView = UIImageView()..{
        $0.image = UIImage(named: "delete")?.withRenderingMode(.alwaysTemplate)
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
        $0.translatesAutoresizingMaskIntoConstraints = false
    }

    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = CustomBlurEffect.effect(withStyle: .dark)
        return UIVisualEffectView(effect: blurEffect)
    }()

    private let backgroundImageView = UIImageView()..{
        $0.contentMode = .scaleAspectFill
    }

    private let darkView = UIView()..{
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }

    private let artworkImageView = UIImageView()..{
        $0.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 100
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.widthAnchor.constraint(equalToConstant: 200).isActive = true
        $0.heightAnchor.constraint(equalToConstant: 200).isActive = true
    }

    private let titleLabel = UILabel()..{
        $0.textColor = .white
        $0.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        $0.textAlignment = .center
    }

    private let detailLabel = UILabel()..{
        $0.textColor = .white
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textAlignment = .center
    }

    private let sourceLabel = UILabel()..{
        $0.textColor = .white
        $0.font = UIFont.systemFont(ofSize: 12)
        $0.alpha = 0.8
        $0.textAlignment = .center
    }

    private lazy var containerStack = UIStackView(arrangedSubviews: [artworkImageView, titleLabel, detailLabel, sourceLabel])..{
        $0.alignment = .fill
        $0.distribution = .fill
        $0.axis = .vertical
        $0.spacing = 8
    }

    private func setupLayout() {
        view.backgroundColor = .black

        view.addSubview(backgroundImageView)
        backgroundImageView.fillSuperview()

        backgroundImageView.addSubview(darkView)
        darkView.fillSuperview()

        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurEffectView)

        containerStack.setCustomSpacing(16, after: artworkImageView)
        containerStack.setCustomSpacing(12, after: titleLabel)
        view.addSubview(containerStack)
        containerStack.centerInSuperview()

        view.addSubview(recordButtonView)
        recordButtonView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        recordButtonView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        recordButtonView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        recordButtonView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        recordButtonView.addSubview(deleteImageView)
        deleteImageView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        deleteImageView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        deleteImageView.centerInSuperview()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()

        airPlayManager = AirPlayManager()..{ $0.delegate = self }

        nowPlayingManager = NowPlayingManager()..{ $0.delegate = self }

        bonjour = BonjourService(
            name: "Coucou",
            hardwareAddress: hardwareAddress
        )
        bonjour?.publish()
    }
}

extension ViewController: NowPlayingManagerDelegate {
    func didUpdateInfo(track: NowPlayingTrack) {
        titleLabel.text = track.title
        detailLabel.text = "\(track.artist ?? "Unknown") - \(track.album ?? "Unknown")"

        if let artworkImageData = track.artworkImageData {
            UIView.animate(withDuration: 0.4, animations: {
                self.artworkImageView.image = UIImage(data: artworkImageData)
                self.backgroundImageView.image = UIImage(data: artworkImageData)
                self.artworkImageView.alpha = 1
                self.backgroundImageView.alpha = 1
            })
        } else {
            artworkImageView.alpha = 0
            backgroundImageView.alpha = 0
        }
    }

    func didUpdateSource(source: NowPlayingSource) {
        switch source {
        case .spotify:
            sourceLabel.text = "Listening on Spotify"
        case .netflix:
            sourceLabel.text = "Watching on Netflix"
        case .shazam:
            sourceLabel.text = "Listening on Shazam"
        case .apple_music:
            sourceLabel.text = "Listening on Apple Music"
        case .unknown:
            sourceLabel.text = "Unknown App"
        }
    }

    func didUpdateIsPlaying(isPlaying: Bool) {
        artworkImageView.alpha = isPlaying ? 1.0 : 0.6
        containerStack.alpha = isPlaying ? 1.0 : 0.6
    }
}

extension ViewController: AirplayManagerProtocol {
    func updateAirplay(routes: [AnyObject]) {
        print("ROUTES", routes)
    }
}
