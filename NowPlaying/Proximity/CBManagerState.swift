import CoreBluetooth

// used for debugging
extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .poweredOff:
            return "powered off"
        case .poweredOn:
            return "powered on"
        case .resetting:
            return "resetting"
        case .unauthorized:
            return "unauthorized"
        case .unknown:
            return "unknown"
        case .unsupported:
            return "unsupported"
        @unknown default:
            return "unknown"
        }
    }
}
