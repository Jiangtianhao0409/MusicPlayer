import AVFoundation

//音频效果器
protocol Effect: AnyObject {
    //控制生效
    var isEnabled: Bool { get set }
    //最后一个节点
    var lastNode: AVAudioNode { get }
    //将效果器内部音频节点注册到音频引擎
    func attach(to engine: AVAudioEngine)
    //将上游节点连接到本效果器的输入端
    func connect(engine: AVAudioEngine, to audioUnit: AVAudioNode, format: AVAudioFormat?)
}
