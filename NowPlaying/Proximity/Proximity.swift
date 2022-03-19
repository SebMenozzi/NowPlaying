import CoreBluetooth

protocol ProximityDelegate: AnyObject {
    func proximityDidUpdate(_ state: Proximity.State)
    func proximityDidUpdate(_ peripherals: [Peripheral])
    func proximityThresholdPassed(by peripheral: Peripheral)
}

/// Proximity tracks discovered BLE devices.
final class Proximity: NSObject {
    struct Constants {
        /// The default threshold for determing when a device is in the immediate
        /// vicinity based on its signal strength (RSSI).
        static let defaultImmediateVicinityThreshold: Double = -40
    }

    // MARK: - Properties
    weak var delegate: ProximityDelegate?

    /// For scanning
    let centralManager = CBCentralManager(delegate: nil, queue: nil)

    /// For advertising
    let peripheralManager = CBPeripheralManager(delegate: nil, queue: nil)

    /// The found BLE peripherals. Updated every time an advertising packet is received
    /// from new or already discovered peripherals.
    var discoveredPeripherals = Set<Peripheral>()

    /**
     The RSSI used to determine immediate vicinity. Any RSSI values greater
     than this will be considred immediate.

     - Note:
     Uses the default (-40) when nil.
     */
    var immediateVicinityThreshold: Double = Constants.defaultImmediateVicinityThreshold

    var state: State = .initializing {
        didSet {
            guard state != oldValue else { return }

            print("State changed to \(state).")

            delegate?.proximityDidUpdate(state)
        }
    }

    override init() {
        super.init()

        centralManager.delegate = self
    }
}

// MARK: Scanning
extension Proximity {
    /**
     Begins to scan for BLE devices. Only scan when necessary and
     call `stopScanning` when finished to preserve battery life.

     - Parameter cbUUIDs: Filter the discovered devices to only those with the specified uuids.

     - Warning: Wait to call this method until `Proximity.state` is `ready`.
    */
    func startScanning(forPeripheralsWith cbUUIDs: [CBUUID]? = nil) {
        guard centralManager.state == .poweredOn else {
            fatalError("BluetoothManager not yet ready to scan. Wait until delegate gets bluetoothManagerBecameReady() call.")
        }

        guard state != .scanning else {
            print("Called \(#function) while already scanning.")
            return
        }

        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(booleanLiteral: false)]
        centralManager.scanForPeripherals(withServices: cbUUIDs, options: options)

        state = .scanning
    }

    /// Stops scanning for peripherals.
    func stopScanning() {
        guard centralManager.isScanning else { return }

        centralManager.stopScan()
        state = .ready
    }
}

// MARK: Advertising
extension Proximity {
    /**
     Begins to advertise. Only advertise when necessary and
     call `stopAdvertising` when finished to preserve battery life.

     - Parameter name: The name to display to other devices.
     - Parameter services: The available services to display).

     - Warning: Wait to call this method until `Proximity.state` is `ready`.
     */
    func startAdvertising(name: String, services: [String]? = nil) {
        var ad: [String: Any] = [CBAdvertisementDataLocalNameKey: name as NSString]

        if let services = services {
            let UUIDs = services.map { CBUUID(string: $0) }
            ad[CBAdvertisementDataServiceUUIDsKey] = NSArray(array: UUIDs)
        }

        peripheralManager.startAdvertising(ad)

        state = .advertising
    }

    /// Stops advertising.
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        state = .ready
    }

}

// MARK: CBCentralManagerDelegate

extension Proximity: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            self.state = .ready
        case .poweredOff:
            self.state = .initializing
            stopScanning()
            stopAdvertising()
            break
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let periph = Peripheral(
            CBPeripheral: peripheral,
            RSSI: RSSI,
            advertisementData: advertisementData
        )

        if let index = discoveredPeripherals.firstIndex(of: periph) {
            discoveredPeripherals.remove(at: index)
        }
        discoveredPeripherals.insert(periph)

        delegate?.proximityDidUpdate(discoveredPeripherals.sorted { lhs, rhs in
            return lhs.RSSI.decimalValue > rhs.RSSI.decimalValue
        })

        if RSSI.doubleValue > immediateVicinityThreshold {
            delegate?.proximityThresholdPassed(by: periph)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral \(peripheral.name ?? "Unknown") connected!")
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print(error ?? "")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let index = discoveredPeripherals.firstIndex(where: { $0.CBPeripheral == peripheral }) {
            discoveredPeripherals.remove(at: index)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension Proximity: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard let index = discoveredPeripherals.firstIndex(where: { $0.CBPeripheral == peripheral }) else {
            return
        }

        var periph = discoveredPeripherals[index]
        periph.RSSI = RSSI
        discoveredPeripherals.remove(at: index)
        discoveredPeripherals.insert(periph)
    }
}
