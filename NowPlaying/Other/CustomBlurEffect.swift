import UIKit

final class CustomBlurEffect: UIBlurEffect {
    private static let customBlurRadius: Float = 100

    class func effect(withStyle style: UIBlurEffect.Style) -> CustomBlurEffect {
        let res = super.init(style: style)
        object_setClass(res, CustomBlurEffect.self)
        return res as! CustomBlurEffect
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        let res = super.copy(with: zone)
        object_setClass(res, CustomBlurEffect.self)
        return res
    }

    static let swizzleImpl: Void = {
        guard let regularImpl = class_getInstanceMethod(CustomBlurEffect.self,#selector(customEffectSettings)),
              let customImpl = class_getInstanceMethod(CustomBlurEffect.self, Selector(("effectSettings"))) else {
            return
        }

        method_exchangeImplementations(customImpl, regularImpl)
    }()

    static func swizzle() {
        _ = swizzleImpl
    }

    @objc func customEffectSettings() -> Any {
        let allocd = NSClassFromString("UIBackdropViewSettingsBlur")!.alloc() as! NSObject
        let initd = allocd.perform(#selector(NSObject.init))!.takeUnretainedValue()
        initd.setValue(NSNumber(value: CustomBlurEffect.customBlurRadius), forKeyPath: "blurRadius")
        return initd
    }
}
