import AVFoundation

/// wrapper around `AVAudioEngine`
/// interface based on `AVAudioPlayer`
final class AudioEngineAdaptor: AudioPlayer, @unchecked Sendable {
    var isPlaying: Bool {
        playerNode.isPlaying
    }
    var isPaused: Bool {
        !playerNode.isPlaying && seekFrame > 0
    }
    /// current time in seconds
    var currentTime: TimeInterval {
        get {
            //最后一次渲染的时间
            guard let nodeTime = playerNode.lastRenderTime,
                  //将时间转换为播放器内部的样本时间
                  let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
                //利用上次seek的进行计算
                return Double(seekFrame) / audioFile.processingFormat.sampleRate
            }
            //计算已经播放了多少帧
            let playedFrames = max(0, AVAudioFramePosition(playerTime.sampleTime))
            //当前帧
            let currentFrame = seekFrame + playedFrames
            //当前时间 = 帧数 / 采样率
            let currentTime = Double(currentFrame) / playerTime.sampleRate
            return currentTime
        }
        set {
            //swift自动提供newValue常量
            let newValue = max(newValue, 0)
            let sampleRate = audioFile.processingFormat.sampleRate
            let totalFrames = audioFile.length
            //将秒转为帧
            let newFrame = AVAudioFramePosition(newValue * sampleRate)
            //newFrame限制在最后一帧以内
            seekFrame = min(newFrame, totalFrames - 1) // don't go past EOF
            //跳转
            seek()
        }
    }
    //总时长
    var duration: TimeInterval {
        guard audioFile.processingFormat.sampleRate > 0 else { return 0 }
        return Double(audioFile.length) / audioFile.processingFormat.sampleRate
    }
    var volume: Float {
        get { playerNode.volume }
        set { playerNode.volume = newValue }
    }
    var isLofiEnabled: Bool {
        lofi.isEnabled
    }
    var isDistortionEnabled: Bool {
        distortion.isEnabled
    }
    var delegate: AudioPlayerDelegate?
    
    private var currentSeekFrame: AVAudioFramePosition {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            //如果没有拿到实时数据，直接返回记录的起始位置
            return seekFrame // previous seekFrame
        }
        //起点 + 相对位移帧数
        let currentFrame = seekFrame + AVAudioFramePosition(playerTime.sampleTime)
        return currentFrame
    }
    
    private var isPlaybackFinished: Bool {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return false
        }
        let currentFrame = seekFrame + AVAudioFramePosition(playerTime.sampleTime)
        //剩余帧数 = 总长度 - 起点
        let framesRemaining = AVAudioFrameCount(audioFile.length - seekFrame)
        //结束帧 = 起点 + 剩余帧数
        let endFrame = seekFrame + AVAudioFramePosition(framesRemaining)
        return currentFrame >= endFrame
    }

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let lofi: Effect = LoFiEffect()
    private let distortion: Effect = DistortionEffect()
    private let mixer = AVAudioMixerNode()
    private let userService = UserService()
    private let audioFile: AVAudioFile
    private var seekFrame: AVAudioFramePosition = 0
    private var didFinishPlaybackTimer: Timer?

    init(contentsOf url: URL) throws {
        self.audioFile = try AVAudioFile(forReading: url)

        setup()
    }
    //@discardableResult 关键字表示返回值可以被忽略，没有处理
    @discardableResult
    func play() -> Bool {
        do {
            //音频播放设备
            if !engine.isRunning {
                try engine.start()
            }
            if !playerNode.isPlaying {
                guard setPlayhead() else {
                    return false
                }
                playerNode.play()
                setupDidFinishPlaybackTimer()
            }
            return true
        } catch {
            logError("failed to start audio engine: \(error)")
            return false
        }
    }

    func pause() {
        guard playerNode.isPlaying else { return }
        //记录当前帧
        seekFrame = currentSeekFrame
        playerNode.stop()
        tearDownDidFinishPlaybackTimer()
    }

    func stop() {
        playerNode.stop()
        tearDownDidFinishPlaybackTimer()
        seekFrame = 0
    }

    func prepareToPlay() -> Bool {
        setPlayhead()
    }

    func setLoFiEnabled(_ isEnabled: Bool) {
        lofi.isEnabled = isEnabled
    }

    func setDistortionEnabled(_ isEnabled: Bool) {
        distortion.isEnabled = isEnabled
    }

    private func setup() {
        engine.attach(playerNode)

        // FIXME: to hear the audio in the simulator, both fx must be enabled 🤷
        #if targetEnvironment(simulator)
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
        #else
        engine.attach(lofi)
        engine.attach(distortion)

        engine.connect(playerNode, to: lofi, format: audioFile.processingFormat)
        engine.connect(lofi, to: distortion, format: audioFile.processingFormat)
        engine.connect(distortion, to: engine.mainMixerNode, format: audioFile.processingFormat)
        #endif

        lofi.isEnabled = userService.isLofiEnabled
        distortion.isEnabled = userService.isDistortionEnabled

        do {
            try engine.start()
        } catch {
            logError("failed to start audio engine: \(error)")
        }
    }

    @discardableResult
    private func setPlayhead() -> Bool {
        //剩余帧数
        let remainingFrames = audioFile.length - seekFrame
        //判断剩余帧是否>0
        guard remainingFrames > 0 else {
            delegate?.audioPlayerDecodeErrorDidOccur(self, error: AudioError.playhead)
            return false
        }
        //安排播放一段音频
        playerNode.scheduleSegment(
            audioFile,
            startingFrame: seekFrame,
            frameCount: AVAudioFrameCount(remainingFrames),
            at: nil,
            completionHandler: nil
        )
        return true
    }

    private func seek() {
        guard playerNode.isPlaying else { return }
        playerNode.stop()
        play()
    }

    private func setupDidFinishPlaybackTimer() {
        //清理旧定时器
        tearDownDidFinishPlaybackTimer()
        //创建新的定时器
        didFinishPlaybackTimer = .scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            //检查是否播放完毕
            guard let self, isPlaybackFinished else { return }
            stop()
            delegate?.audioPlayerDidFinishPlaying(self, successfully: true)
        }
    }

    //定时器销毁函数
    private func tearDownDidFinishPlaybackTimer() {
        didFinishPlaybackTimer?.invalidate()
        didFinishPlaybackTimer = nil
    }
}

private extension AudioEngineAdaptor {
    enum AudioError: Error {
        case playhead
    }
}

//扩展AVAudioEngine的能力，链接自定义的效果
private extension AVAudioEngine {
    /// attach an effect
    func attach(_ node: Effect) {
        node.attach(to: self)
    }

    /// connect a node to an effect
    func connect(_ node1: AVAudioNode, to node2: Effect, format: AVAudioFormat?) {
        node2.connect(engine: self, to: node1, format: format)
    }

    /// connect an effect to a node
    func connect(_ node1: Effect, to node2: AVAudioNode, format: AVAudioFormat?) {
        connect(node1.lastNode, to: node2, format: format)
    }

    /// connect an effect to an effect
    func connect(_ node1: Effect, to node2: Effect, format: AVAudioFormat?) {
        node2.connect(engine: self, to: node1.lastNode, format: format)
    }
}
