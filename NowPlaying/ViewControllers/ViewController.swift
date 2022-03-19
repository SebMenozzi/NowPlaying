import UIKit
import CoreBluetooth

final class ViewController: UIViewController {
    private var airPlayManager: AirPlayManager?
    private var nowPlayingManager: NowPlayingManager?

    private let rotationAmplitude: CGFloat = CGFloat(30.0.degreesToRadians)
    private var parallaxEffects: [ParallaxEffect] = []

    private var isConnected = false

    let proximity = Proximity()
    var connectedPeripheral: CBPeripheral?

    private lazy var recordButtonView = UIView()..{
        $0.backgroundColor = UIColor.blue
        $0.makeCorner(withRadius: 20)
        $0.translatesAutoresizingMaskIntoConstraints = false

        let tap = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        tap.minimumPressDuration = 0
        tap.cancelsTouchesInView = false
        $0.addGestureRecognizer(tap)
    }

    private func openApp(with bundleID: String) -> Bool {
        guard let obj = objc_getClass("LSApplicationWorkspace") as? NSObject else { return false }
        let workspace = obj.perform(Selector(("defaultWorkspace")))?.takeUnretainedValue() as? NSObject

        return workspace?.perform(Selector(("openApplicationWithBundleID:")), with: bundleID) != nil
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

    private let backgroundImageView = UIImageView()..{
        $0.contentMode = .scaleAspectFill
    }

    private let darkView = UIView()..{
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    }

    private let artworkImageView = UIImageView()..{
        $0.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 100
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.widthAnchor.constraint(equalToConstant: 200).isActive = true
        $0.heightAnchor.constraint(equalToConstant: 200).isActive = true

        // Add rotation to the artwork
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue =  Double.pi * 2.0
        animation.duration = 10
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false

        //$0.layer.add(animation, forKey: "spin")
    }

    private let titleLabel = UILabel()..{
        $0.textColor = .white
        $0.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        $0.textAlignment = .center
    }

    private lazy var detailLabel = MarqueeLabel()..{
        $0.textColor = .white
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textAlignment = .center
        $0.type = .continuous
        $0.speed = .duration(10)
        $0.fadeLength = 10.0
        $0.leadingBuffer = 0
        $0.trailingBuffer = 0
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

    @objc func didEnterBackgroundNotification(_ notification: NSNotification) {
        //_ = openApp(with: "co.seb.NowPlaying")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        proximity.delegate = self

        parallaxEffects.append(ParallaxEffect(view: artworkImageView, rotationWithMaxAngle: -rotationAmplitude))
        parallaxEffects.append(ParallaxEffect(view: artworkImageView, tiltWithMaxOffset: -10))

        setupLayout()

        startTilting()

        airPlayManager = AirPlayManager()..{ $0.delegate = self }

        nowPlayingManager = NowPlayingManager()..{ $0.delegate = self }
    }
}

extension ViewController: ProximityDelegate {

    func proximityDidUpdate(_ state: Proximity.State) {
        if state == .ready {
            proximity.startScanning()
        }
    }

    func proximityDidUpdate(_ peripherals: [Peripheral]) {
        print("\nPeripherals:")
        for peripheral in peripherals {
            if let name = peripheral.name {
                print("-", name, peripheral.RSSI.decimalValue/*, peripheral.CBPeripheral.state.description*/)

                if name == "Bites" && !isConnected {
                    connectedPeripheral = peripheral.CBPeripheral
                    proximity.centralManager.connect(connectedPeripheral!)
                    isConnected = true
                    proximity.stopScanning()
                    break
                }
            }
        }
    }

    func proximityThresholdPassed(by peripheral: Peripheral) {
        //print("Nearby", peripheral.name, peripheral.RSSI.decimalValue)
    }

}

// MARK: Parallax Artwork Image View
extension ViewController {
    private func startTilting() {
        parallaxEffects.forEach {
            $0.enableMotionEffect()
        }
    }
}

extension ViewController: NowPlayingManagerDelegate {
    private func blurImage(image: UIImage, blurRadius: CGFloat) -> UIImage? {
        let ciContext = CIContext(options: nil)

        guard let inputImage = CIImage(image: image),
            let mask = CIFilter(name: "CIGaussianBlur") else {
            return nil
        }

        mask.setValue(inputImage, forKey: kCIInputImageKey)
        mask.setValue(blurRadius, forKey: kCIInputRadiusKey) // Set your blur radius here

        guard let output = mask.outputImage,
            let cgImage = ciContext.createCGImage(output, from: inputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    func didUpdateInfo(track: NowPlayingTrack) {
        titleLabel.text = track.title
        detailLabel.text = "\(track.artist ?? "Unknown") - \(track.album ?? "Unknown")"

        if let artworkImageData = track.artworkImageData {
            UIView.animate(withDuration: 0.4, animations: {
                self.artworkImageView.image = UIImage(data: artworkImageData)
                self.backgroundImageView.image = self.blurImage(image: UIImage(data: artworkImageData)!, blurRadius: 10)!
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
    func updateAirplay(routes: [MPAVRouteProtocol]) {
        for route in routes {
            let isPicked = route.isPicked!()
            let name = route.routeName!()

            print(name, isPicked)
        }
    }
}
