import UIKit

protocol MusicPlayerControl {
    //按钮显示的图标
    var image: UIImage { get set }
    //语音朗读的文本
    var accessibilityLabel: String { get set }
    //按钮是否禁用
    var isDisabled: Bool { get set }
    //当前旋转角度
    var rotation: Double { get set }
    //允许的最大旋转角度
    var maxRotation: Double { get set }
    //当前缩放比例
    var scale: Double { get set }
    //允许的最大缩放比例
    var maxScale: Double { get set }
    //当前透明度
    var opacity: Double { get }

    mutating func reset()
    mutating func animate()
}

struct MusicPlayerButton: MusicPlayerControl {
    var image: UIImage
    var accessibilityLabel: String
    var isDisabled: Bool
    var rotation = 0.0
    var maxRotation = 0.0
    var scale = 1.0
    var maxScale = 1.3
    var opacity: Double {
        isDisabled ? 0.5 : 1.0
    }

    mutating func reset() {
        rotation = 0
        scale = 1
    }

    mutating func animate() {
        rotation = maxRotation
        scale = maxScale
    }
}

struct MusicPlayerFXButton: MusicPlayerControl {
    var image: UIImage
    var accessibilityLabel: String
    var isDisabled = false
    var isFXEnabled: Bool
    var rotation = 0.0
    var maxRotation = 0.0
    var scale = 1.0
    var maxScale = 1.3
    var opacity: Double {
        isFXEnabled ? 1.0 : 0.5
    }

    mutating func reset() {
        rotation = 0
        scale = 1
    }

    mutating func animate() {
        rotation = maxRotation
        scale = maxScale
    }
}
