import Foundation
import MediaPlayer

@objc protocol AuthorHelperProtocol {
}

protocol NowPlayingManagerDelegate: AnyObject {
    func didUpdateInfo(track: NowPlayingTrack)
    func didUpdateIsPlaying(isPlaying: Bool)
    func didUpdateSource(source: NowPlayingSource)
}

final class NowPlayingManager: NSObject {
    weak var delegate: NowPlayingManagerDelegate?

    // MARK:  - Private

    private typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
    private typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    private typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    private typealias MRMediaRemoteGetNowPlayingClientFunction = @convention(c) (DispatchQueue, @escaping (AnyObject) -> Void) -> Void
    private typealias MRNowPlayingClientGetBundleIdentifierFunction = @convention(c) (AnyObject?) -> String
    private typealias MRMediaRemoteGetNowPlayingApplicationPIDFunction = @convention(c) (DispatchQueue, @escaping (Int) -> Void) -> Void

    private enum MRCommand: Int {
        case kMRPlay = 0, kMRPause, kMRTogglePlayPause, kMRNextTrack, kMRPreviousTrack
    }
    private typealias MRMediaRemoteSendCommandFunction = @convention(c) (Int, AnyObject?) -> Bool

    private typealias MRNowPlayingClientCreateFunction = @convention(c) (AnyObject?, String?) -> AnyObject

    private typealias MRMediaRemoteSendCommandToClientFunction = @convention(c) (Int, [String: Any]?, AnyObject?, AnyObject?, Int, Int, AnyObject?) -> AnyObject

    private var MRMediaRemoteGetNowPlayingInfo: MRMediaRemoteGetNowPlayingInfoFunction?
    private var MRMediaRemoteGetNowPlayingApplicationIsPlaying: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction?
    private var MRMediaRemoteGetNowPlayingClient: MRMediaRemoteGetNowPlayingClientFunction?
    private var MRNowPlayingClientGetBundleIdentifier: MRNowPlayingClientGetBundleIdentifierFunction?
    private var MRMediaRemoteGetNowPlayingApplicationPID: MRMediaRemoteGetNowPlayingApplicationPIDFunction?
    private var kMRMediaRemoteNowPlayingApplicationClientStateDidChange: CFString?
    private var MRMediaRemoteSendCommand: MRMediaRemoteSendCommandFunction?
    private var MRNowPlayingClientCreate: MRNowPlayingClientCreateFunction?
    private var MRMediaRemoteSendCommandToClient: MRMediaRemoteSendCommandToClientFunction?

    private func registerNotifications() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "kMRMediaRemoteNowPlayingApplicationDidChangeNotification"), object: nil, queue: nil) { _ in
            self.updateApp()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "kMRMediaRemoteNowPlayingApplicationClientStateDidChange"), object: nil, queue: nil) { _ in
            self.updateInfo()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "kMRNowPlayingPlaybackQueueChangedNotification"), object: nil, queue: nil) { _ in
            self.updateInfo()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "kMRPlaybackQueueContentItemsChangedNotification"), object: nil, queue: nil) { _ in
            self.updateInfo()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"), object: nil, queue: nil) { (notification) in
            self.updateState()
        }
    }

    private static let maxRetry = 4
    private var retry = 0

    private func updateInfo() {
        guard let MRMediaRemoteGetNowPlayingInfo = MRMediaRemoteGetNowPlayingInfo else {
            return
        }

        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { (info) in
            let artist = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String
            let title = info["kMRMediaRemoteNowPlayingInfoTitle"] as? String
            let album = info["kMRMediaRemoteNowPlayingInfoAlbum"] as? String
            let artworkImageData = info["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data
            let externalIdentifier = info["kMRMediaRemoteNowPlayingInfoExternalContentIdentifier"] as? String
            let contentIdentifier = info["kMRMediaRemoteNowPlayingInfoContentItemIdentifier"] as? String
            let collectionIdenfier = info["kMRMediaRemoteNowPlayingInfoCollectionIdentifier"] as? String
            let artworkIdentifier = info["kMRMediaRemoteNowPlayingInfoArtworkIdentifier"] as? String
            let timestamp = info["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date
            let elapsedTime = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double
            let duration = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double

            let track = NowPlayingTrack(
                artist: artist,
                title: title,
                album: album,
                artworkImageData: artworkImageData,
                externalIdentifier: externalIdentifier,
                contentIdentifier: contentIdentifier,
                collectionIdenfier: collectionIdenfier,
                artworkIdentifier: artworkIdentifier,
                timestamp: timestamp,
                elapsedTime: elapsedTime,
                duration: duration
            )

            if artworkImageData == nil {
                self.updateInfo()
            } else {
                self.retry += 1

                if self.retry < Self.maxRetry {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.updateInfo()
                    }
                } else {
                    self.delegate?.didUpdateInfo(track: track)
                    self.retry = 0
                }
            }
        })
    }

    private func updateState() {
        guard let MRMediaRemoteGetNowPlayingApplicationIsPlaying = MRMediaRemoteGetNowPlayingApplicationIsPlaying else {
            return
        }

        MRMediaRemoteGetNowPlayingApplicationIsPlaying(DispatchQueue.main, { (isPlaying) in
            self.delegate?.didUpdateIsPlaying(isPlaying: isPlaying)
        })
    }
    

    private func updateApp() {
        guard let MRMediaRemoteGetNowPlayingClient = MRMediaRemoteGetNowPlayingClient,
              let MRNowPlayingClientGetBundleIdentifier = MRNowPlayingClientGetBundleIdentifier else {
            return
        }

        MRMediaRemoteGetNowPlayingClient(DispatchQueue.main, { (clientObj) in
            let appBundleIdentifier = MRNowPlayingClientGetBundleIdentifier(clientObj)

            print(appBundleIdentifier)

            switch appBundleIdentifier {
            case "com.spotify.client":
                self.delegate?.didUpdateSource(source: .spotify)
            case "com.apple.Music":
                self.delegate?.didUpdateSource(source: .apple_music)
            case "com.netflix.Netflix":
                self.delegate?.didUpdateSource(source: .netflix)
            case "com.shazam.Shazam":
                self.delegate?.didUpdateSource(source: .shazam)
            default:
                self.delegate?.didUpdateSource(source: .unknown)
            }
        })
    }

    private func updateAppPID() {
        guard let MRMediaRemoteGetNowPlayingApplicationPID = MRMediaRemoteGetNowPlayingApplicationPID else {
            return
        }

        MRMediaRemoteGetNowPlayingApplicationPID(DispatchQueue.main, { (pid) in
            print(pid)
        })
    }

    private func setup() {
        // MARK: -  Load Framework
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))
        
        // MARK: - Retrieve MRMediaRemoteRegisterForNowPlayingNotifications function
        guard let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString) else {
            return
        }

        let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)

        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.global(qos: .utility))

        // MARK: - Retrieve MRMediaRemoteGetNowPlayingInfo function
        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
            return
        }
        MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

        // MARK: - Retrieve MRMediaRemoteGetNowPlayingApplicationIsPlaying function
        guard let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString) else {
            return
        }
        MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)

        // MARK: - Retrieve MRMediaRemoteGetNowPlayingClient function
        guard let MRMediaRemoteGetNowPlayingClientPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingClient" as CFString) else {
            return
        }
        MRMediaRemoteGetNowPlayingClient = unsafeBitCast(MRMediaRemoteGetNowPlayingClientPointer, to: MRMediaRemoteGetNowPlayingClientFunction.self)

        // MARK: - Retrieve MRNowPlayingClientGetBundleIdentifier function
        guard let MRNowPlayingClientGetBundleIdentifierPointer = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetBundleIdentifier" as CFString) else {
            return
        }
        MRNowPlayingClientGetBundleIdentifier = unsafeBitCast(MRNowPlayingClientGetBundleIdentifierPointer, to: MRNowPlayingClientGetBundleIdentifierFunction.self)

        // MARK: - Retrieve MRNowPlayingClientGetBundleIdentifier function
        guard let MRMediaRemoteGetNowPlayingApplicationPIDPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationPID" as CFString) else {
            return
        }
        MRMediaRemoteGetNowPlayingApplicationPID = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationPIDPointer, to: MRMediaRemoteGetNowPlayingApplicationPIDFunction.self)

        // MARK: - Retrieve MRMediaRemoteSendCommand function
        guard let MRMediaRemoteSendCommandPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString) else {
            return
        }
        MRMediaRemoteSendCommand = unsafeBitCast(MRMediaRemoteSendCommandPointer, to: MRMediaRemoteSendCommandFunction.self)

        // MARK: - Retrieve MRNowPlayingClientCreate function
        guard let MRNowPlayingClientCreatePointer = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientCreate" as CFString) else {
            return
        }

        MRNowPlayingClientCreate = unsafeBitCast(MRNowPlayingClientCreatePointer, to: MRNowPlayingClientCreateFunction.self)

        // MARK: - MRMediaRemoteSendCommandToClient function
        guard let MRMediaRemoteSendCommandToClientPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommandToClient" as CFString) else {
            return
        }

        MRMediaRemoteSendCommandToClient = unsafeBitCast(MRMediaRemoteSendCommandToClientPointer, to: MRMediaRemoteSendCommandToClientFunction.self)
    }

    private func updateAll() {
        updateState()
        updateInfo()
        updateApp()
        updateAppPID()
    }

    override init() {
        super.init()

        registerNotifications()
        setup()
        updateAll()

        /*
        guard let MRNowPlayingClientCreate = MRNowPlayingClientCreate,
              let MRMediaRemoteSendCommandToClient = MRMediaRemoteSendCommandToClient else {
            return
        }

        let args: [String : Any]? = ["kMRMediaRemoteOptionDisableImplicitAppLaunchBehaviors": false]

        let client = MRNowPlayingClientCreate(nil, "com.netflix.Netflix")

        //let test = MRMediaRemoteSendCommandToClient(2, args, nil, client, 1, 0, nil)

        print("CLIENT", client)
        */
    }

    // MARK: - Public

    public func togglePlayingState() {
        guard let MRMediaRemoteSendCommand = MRMediaRemoteSendCommand else { return }

        _ = MRMediaRemoteSendCommand(MRCommand.kMRTogglePlayPause.rawValue, nil)
    }

    public func skipToNextTrack() {
        guard let MRMediaRemoteSendCommand = MRMediaRemoteSendCommand else { return }

        _ = MRMediaRemoteSendCommand(MRCommand.kMRNextTrack.rawValue, nil)
    }

    public func skipToPreviousTrack() {
        guard let MRMediaRemoteSendCommand = MRMediaRemoteSendCommand else { return }

        _ = MRMediaRemoteSendCommand(MRCommand.kMRPreviousTrack.rawValue, nil)
    }
}
