import UIKit

struct ParallaxEffect {
    let view: UIView
    let axes: [ParallaxAxis]

    let animationFactor: CGFloat = 0.3

    init(view: UIView, rotationWithMaxAngle maxAngle: CGFloat) {
        self.view = view

        axes = [
            ParallaxAxis(
                layerKeyPath: "transform.rotation.y",
                minValue: maxAngle,
                maxValue: -maxAngle,
                type: .tiltAlongHorizontalAxis
            ),
            ParallaxAxis(
                layerKeyPath: "transform.rotation.x",
                minValue: -maxAngle,
                maxValue: maxAngle,
                type: .tiltAlongVerticalAxis
            )
        ]
    }

    init(view: UIView, tiltWithMaxOffset maxOffset: CGFloat) {
        self.init(view: view, tiltWithHorizontalMaxOffset: maxOffset, verticalMaxOffset: maxOffset)
    }

    init(view: UIView, tiltWithHorizontalMaxOffset hMaxOffset: CGFloat, verticalMaxOffset vMaxOffset: CGFloat) {
        self.view = view

        axes = [
            ParallaxAxis(
                layerKeyPath: "transform.translation.x",
                minValue: -hMaxOffset,
                maxValue: hMaxOffset,
                type: .tiltAlongHorizontalAxis
            ),
            ParallaxAxis(
                layerKeyPath: "transform.translation.y",
                minValue: -vMaxOffset,
                maxValue: vMaxOffset,
                type: .tiltAlongVerticalAxis
            )
        ]
    }

    func enableMotionEffect() {
        guard !axes.isEmpty else { return }
        let effects = axes.map { $0.motionEffect }

        let group = UIMotionEffectGroup()
        group.motionEffects = effects
        view.addMotionEffect(group)
    }

    func removeMotionEffect() {
        // TODO: this removes all motion effects though it
        // should only remove the ones it added
        view.motionEffects.forEach(view.removeMotionEffect(_:))
    }

    func startAnimating() {
        axes.enumerated().forEach { (index, axis) in
            let animation = axis.animation(factor: animationFactor)
            view.layer.add(animation, forKey: "axis\(index)")
        }
    }

    func stopAnimating() {
        // TODO :this removes all animations though it
        // should only remove the ones it added
        view.layer.removeAllAnimations()
    }
}

struct ParallaxAxis {
    let layerKeyPath: String
    let minValue: CGFloat
    let maxValue: CGFloat
    let type: UIInterpolatingMotionEffect.EffectType

    var motionEffect: UIMotionEffect {
        let viewKeypath = "layer.\(layerKeyPath)"
        let effect = UIInterpolatingMotionEffect(keyPath: viewKeypath, type: type)
        effect.minimumRelativeValue = minValue
        effect.maximumRelativeValue = maxValue
        return effect
    }

    private let loopTime: CFTimeInterval = 4.0
    private let loopCount: Int = 6

    func animation(factor: CGFloat) -> CAAnimation {
        let animation = CAKeyframeAnimation(keyPath: layerKeyPath)
        let (min, max) = (minValue * factor, maxValue * factor)

        let loop: [CGFloat]
        switch type {
        case .tiltAlongHorizontalAxis:
            loop = [min, 0, max, 0]
        default:
            loop = [0, min, 0, max]
        }
        let values = repeatElement(loop, count: loopCount).flatMap { $0 } + [loop.first!]
        animation.values = values
        animation.calculationMode = .cubicPaced
        animation.duration = loopTime * CFTimeInterval(loopCount)
        animation.isRemovedOnCompletion = false
        animation.repeatCount = Float.greatestFiniteMagnitude
        animation.timeOffset = loopTime / CFTimeInterval(4.0)

        return animation
    }
}
