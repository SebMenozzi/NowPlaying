import Foundation

extension Proximity {
    public enum State {
        /// Proximity is not ready to begin scanning or advertising. Bluetooth is powering on.
        case initializing
        /// Proximity is ready to begin scanning or advertising.
        case ready
        /// Proximity is scanning.
        case scanning
        /// Proximity is advertising.
        case advertising
    }
}

extension Proximity.State: CustomStringConvertible {
    var description: String {
        switch self {
        case .initializing: return "initializing"
        case .ready: return "ready"
        case .scanning: return "scanning"
        case .advertising: return "advertising"
        }
    }
}
