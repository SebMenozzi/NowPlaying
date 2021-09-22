struct Constants {
    // Public ID (can be GUID, MAC, some string)
    static let publicID = "b08f5a79-db29-4384-b456-a4784d9e6055"

    static let SERVER_VERSION = "366.0"
    static let SERVER = "AirTunes/\(SERVER_VERSION)"

    static let FEATURES: UInt64 = Features(rawValue: 0) // all zeros
        .union(Features.Ft48TransientPairing)
        .union(Features.Ft47PeerMgmt)
        .union(Features.Ft47PeerMgmt)
        .union(Features.Ft46HKPairing)
        .union(Features.Ft41_PTPClock)
        .union(Features.Ft40BufferedAudio)
        .union(Features.Ft30UnifiedAdvertInf)
        .union(Features.Ft22AudioUnencrypted)
        .union(Features.Ft20RcvAudAAC_LC)
        .union(Features.Ft19RcvAudALAC)
        .union(Features.Ft18RcvAudPCM)
        .union(Features.Ft17AudioMetaTxtDAAP)
        .union(Features.Ft16AudioMetaProgres)
        .union(Features.Ft14MFiSoftware)
        .union(Features.Ft09AirPlayAudio)
        .union(Features.Ft07ScreenMirroring)
        .rawValue

}
