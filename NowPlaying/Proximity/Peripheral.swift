import CoreBluetooth

/// received signal strength indicator
typealias RSSI = NSNumber

/// Represents a bluetooth device. Mostly a wrapper for a `CBPeripheral` found in the
/// `peripheral` property.
struct Peripheral {
    /// The object returned from CoreBluetooth.
    public let CBPeripheral: CBPeripheral
    /// The signal strength.
    public var RSSI: RSSI
    /// Check `CBAdvertisementData` for possible keys.
    public let advertisementData: [String : Any]
}

// MARK: - Extensions
extension Peripheral: Equatable {
    static func == (lhs: Peripheral, rhs: Peripheral) -> Bool {
        return lhs.CBPeripheral == rhs.CBPeripheral
    }
}

extension Peripheral: Hashable {
    var hashValue: Int {
        return CBPeripheral.hashValue
    }
}

extension Peripheral {
    var advertisedServices: [String]? {
        guard let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] else { return nil }

        return services.map { $0.uuidString }
    }

    /// The Tx power level
    var transmitPower: Double? {
        return advertisementData[CBAdvertisementDataTxPowerLevelKey] as? Double
    }

    /// The name of the device.
    var name: String? {
        return CBPeripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }

    /// The manufacturer data. Returns the value of `CBAdvertisementDataManufacturerDataKey`
    /// from the `advertisementData`.
    var manufacturerData: Data? {
        return advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }
}

extension CBPeripheralState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .connected: return "connected"
        case .connecting: return "connecting"
        case .disconnected: return "disconnected"
        case .disconnecting: return "disconnecting"
        @unknown default:
            return "unknown"
        }
    }
}
