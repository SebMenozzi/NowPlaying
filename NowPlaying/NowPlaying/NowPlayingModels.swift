import Foundation

enum NowPlayingSource {
    case spotify
    case netflix
    case shazam
    case apple_music
    case unknown
}

struct NowPlayingTrack: Equatable {
    let artist: String?
    let title: String?
    let album: String?
    let artworkImageData: Data?
    let externalIdentifier: String?
    let contentIdentifier: String?
    let collectionIdenfier: String?
    let artworkIdentifier: String?
    let timestamp: Date?
    let elapsedTime: Double?
    let duration: Double?

    static func == (lhs: NowPlayingTrack, rhs: NowPlayingTrack) -> Bool {
        return (
            lhs.artist == rhs.artist &&
            lhs.title == rhs.title &&
            lhs.album == rhs.album &&
            lhs.artworkImageData == rhs.artworkImageData &&
            lhs.externalIdentifier == rhs.externalIdentifier &&
            lhs.contentIdentifier == rhs.contentIdentifier &&
            lhs.collectionIdenfier == rhs.collectionIdenfier &&
            lhs.timestamp == rhs.timestamp &&
            lhs.elapsedTime == rhs.elapsedTime &&
            lhs.duration == rhs.duration
        )
    }
}
