import Foundation
import MediaPlayer
//MARK - 自定义播放状态 和 系统播放状态之间的互相转化


//String类型的结果，Sendable表示可以在并发环境中安全传递
enum RepeatMode: String, Sendable {
    case none //不重复
    case one  //单曲循环
    case all  //列表循环
}

//扩展：桥接到系统类型
extension RepeatMode {
    //将我自己定义的类型结果转化为适配ios的MPRepeatType
    var remote: MPRepeatType {
        switch self {
        case .none:
            return .off
        case .one:
            return .one
        case .all:
            return .all
        }
    }

    //下一个模式：点击循环按钮切换模式，点击当前切换到下一个
    func next() -> RepeatMode {
        switch self {
        case .none:
            return .one
        case .one:
            return .all
        case .all:
            return .none
        }
    }

    //原地切换的方法
    mutating func toggle() {
        switch self {
        case .none:
            self = .one
        case .one:
            self = .all
        case .all:
            self = .none
        }
    }
}

//当用户从锁屏界面中点击重复按钮时，回调获取系统类型转化为自定义枚举类型
extension MPRepeatType {
    var repeatMode: RepeatMode {
        switch self {
        case .off:
            return .none
        case .one:
            return .one
        case .all:
            return .all
        default:
            assertionFailure("unhandled MPRepeatType")
            return .none
        }
    }
}
