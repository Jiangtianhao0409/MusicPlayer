import Foundation
import MediaPlayer

//支持依赖注入，测试替身
//AnyObject限制为引用类型，只有类可以遵循这个协议
//Sendable：保证并发传输安全
protocol UserServicing: AnyObject, Sendable {
    //重复模式：连续播放，重复单曲还是随机播
    var repeatMode: RepeatMode? { get set }
    //当前播放的音频ID
    var currentTrackID: MPMediaEntityPersistentID? { get set }
    //播放器中所有歌曲的ID列表
    var trackIDs: [MPMediaEntityPersistentID]? { get set }
    //是否开启 Lo-fi 音效
    var isLofiEnabled: Bool { get set }
    //是否开启失真效果
    var isDistortionEnabled: Bool { get set }
}

final class UserService: UserServicing, @unchecked Sendable {
    //数据持久化
    private let userDefaults: UserDefaults
    //线程队列
    private let queue = DispatchQueue(
        label: "UserService.userDefaultsQueue",
        attributes: .concurrent
    )

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var repeatMode: RepeatMode? {
        //获取
        get {
            //同步执行：调用线程会阻塞等待读取完成
            queue.sync {
                //线程安全的同步自定义枚举和系统默认的值
                guard let rawValue = userDefaults.string(forKey: Key.repeatMode.rawValue) else {
                    return nil
                }
                return RepeatMode(rawValue: rawValue)
            }
        }
        //写入
        set {
            //async表示异步操作，barrier标志表示写操作独占队列，确保之前所有的读写操作完成之后才执行写操作
            //swift写闭包的方式
            // { 闭包开始 [weak self] 捕获列表 in 分隔符，从这里开始是闭包的执行代码
            queue.async(flags: .barrier) { [weak self] in
                self?.userDefaults.set(newValue?.rawValue, forKey: Key.repeatMode.rawValue)
            }
        }
    }

    var currentTrackID: MPMediaEntityPersistentID? {
        get {
            queue.sync {
                userDefaults.value(forKey: Key.currentTrackID.rawValue) as? MPMediaEntityPersistentID
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?.userDefaults.set(newValue, forKey: Key.currentTrackID.rawValue)
            }
        }
    }

    var trackIDs: [MPMediaEntityPersistentID]? {
        get {
            queue.sync {
                userDefaults.array(forKey: Key.tracks.rawValue) as? [MPMediaEntityPersistentID]
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?.userDefaults.set(newValue, forKey: Key.tracks.rawValue)
            }
        }
    }

    var isLofiEnabled: Bool {
        get {
            queue.sync {
                userDefaults.bool(forKey: Key.lofi.rawValue)
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?.userDefaults.set(newValue, forKey: Key.lofi.rawValue)
            }
        }
    }

    var isDistortionEnabled: Bool {
        get {
            queue.sync {
                userDefaults.bool(forKey: Key.distortion.rawValue)
            }
        }
        set {
            queue.async(flags: .barrier) { [weak self] in
                self?.userDefaults.set(newValue, forKey: Key.distortion.rawValue)
            }
        }
    }
}

private extension UserService {
    enum Key: String {
        case repeatMode
        case tracks
        case currentTrackID
        case lofi
        case distortion
    }
}
