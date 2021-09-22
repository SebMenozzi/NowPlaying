import Foundation
import MediaPlayer
import AVFoundation

protocol AirplayManagerProtocol: AnyObject {
    func updateAirplay(routes: [AnyObject])
}

final class AirPlayManager: NSObject {
    weak var delegate: AirplayManagerProtocol?

    let MPAudioDeviceControllerClass: NSObject.Type = NSClassFromString("MPAudioDeviceController") as! NSObject.Type
    let MPAVRoutingControllerClass: NSObject.Type = NSClassFromString("MPAVRoutingController") as! NSObject.Type

    var routingController: MPAVRoutingControllerProtocol
    var audioDeviceController: MPAudioDeviceControllerProtocol

    override init() {
        routingController = MPAVRoutingControllerClass.init() as MPAVRoutingControllerProtocol
        audioDeviceController = MPAudioDeviceControllerClass.init() as MPAudioDeviceControllerProtocol

        super.init()

        audioDeviceController.setDelegate!(self)
        routingController.setDelegate!(self)
        updateAirPlayDevices()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateAirPlayDevices),
            name: .MPVolumeViewWirelessRouteActiveDidChange,
            object: nil
        )
    }

    @objc func updateAirPlayDevices() {
        routingController.fetchAvailableRoutes?(completionHandler: { (routes) in
            for route in routes {
                guard let devices = route.outputDevices?() else { continue }

                for device in devices {
                    print(device.name?())
                }
            }

            self.delegate?.updateAirplay(routes: routes)
        })
    }
    // MARK: - MPAVRoutingControllerDelegate

    func routingControllerAvailableRoutesDidChange(controller: MPAVRoutingControllerProtocol) {
        updateAirPlayDevices()
    }
}

// MARK: - MPProtocols
@objc protocol MPAVRoutingControllerProtocol {
    @objc optional func fetchAvailableRoutes(completionHandler: @escaping (_ routes: [MPAVRouteProtocol]) -> Void)
    @objc optional func setDelegate(_ delegate: NSObject)
}

@objc protocol MPAVRouteProtocol {
    @objc optional func routeName() -> String
    @objc optional func routeSubtype() -> Int
    @objc optional func routeType() -> Int
    @objc optional func requiresPassword() -> Bool
    @objc optional func routeUID() -> String
    @objc optional func isPicked() -> Bool
    @objc optional func passwordType() -> Int
    @objc optional func wirelessDisplayRoute() -> MPAVRouteProtocol
    @objc optional func outputDevices() -> [MRAVOutputDeviceProtocol]
}

// https://developer.limneos.net/index.php?ios=14.4&framework=MediaRemote.framework&header=MRAVOutputDevice.h
@objc protocol MRAVOutputDeviceProtocol {
    @objc optional func name() -> String
    @objc optional func deviceSubtype() -> Int
    @objc optional func deviceType() -> Int
    @objc optional func batteryLevel() -> Float
    @objc optional func hasBatteryLevel() -> Bool
    @objc optional func volume() -> Float
    @objc optional func bluetoothID() -> String
    @objc optional func uid() -> String
}

@objc protocol MPAudioDeviceControllerProtocol {
    @objc optional func setDelegate(_ delegate: NSObject)
}

@objc protocol AVOutputDeviceProtocol {
    @objc optional func batteryLevel() -> Float
}

// IMPORTANT: Mandatory otherwise casting will fail!
extension NSObject: MPAVRoutingControllerProtocol, MPAVRouteProtocol, MPAudioDeviceControllerProtocol, MRAVOutputDeviceProtocol, AVOutputDeviceProtocol {
}
