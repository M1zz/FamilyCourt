import AVFoundation
import UIKit
import LeeoKit

/// 의사봉(탕탕탕)과 타이머 종료음을 합성해서 재생해요.
///
/// 오디오 세션 · 엔진은 메인 스레드에서 다루지 않는다. `setActive(true)` 는 시스템 오디오 서버를
/// 기다리는 동기 호출이고 `engine.start()` 는 첫 재생과 백그라운드에서 돌아온 뒤마다 오디오 장치를
/// 다시 여는데, 다른 앱이 소리를 쥐고 있거나 이어폰이 바뀌는 중이면 수백 ms 까지 걸려
/// 의사봉을 두드리는 순간 화면이 멈칫했다. 진동만 메인에서 바로 내고, 소리는 전용 큐에서 낸다.
final class SoundPlayer: @unchecked Sendable {

    static let shared = SoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    /// 엔진 · 세션 · 버퍼는 이 큐에서만 만진다.
    private let queue = DispatchQueue(label: "familycourt.sound", qos: .userInitiated)
    private var isSetUp = false
    /// 합성은 한 번만 — 같은 소리를 두드릴 때마다 다시 만들 까닭이 없다.
    private lazy var gavelSound = gavelBuffer()
    private lazy var beepSound = beepBuffer()

    private init() {}

    func gavel() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        play { $0.gavelSound }
    }

    func beep() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        play { $0.beepSound }
    }

    private func play(_ sound: @escaping (SoundPlayer) -> AVAudioPCMBuffer?) {
        // 원격 킬스위치 — 끄면 소리만 쉬고 진동은 위에서 이미 났다.
        guard LeeoRemoteFlags.isEnabled(FamilyCourtFlag.synthSoundEnabled) else { return }
        queue.async { [self] in
            guard let buffer = sound(self) else { return }
            setUpIfNeeded()
            try? AVAudioSession.sharedInstance().setActive(true)
            if !engine.isRunning { try? engine.start() }
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: .interrupts)
            player.play()
        }
    }

    private func setUpIfNeeded() {
        guard !isSetUp else { return }
        isSetUp = true
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    private func emptyBuffer(duration: Double) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return nil }
        let frames = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        return buffer
    }

    /// 나무 두드리는 소리 3번 — 낮은 음으로 떨어지는 짧은 타격음
    private func gavelBuffer() -> AVAudioPCMBuffer? {
        guard let buffer = emptyBuffer(duration: 0.85) else { return nil }
        let samples = buffer.floatChannelData![0]
        let total = Int(buffer.frameLength)
        for start in [0.0, 0.28, 0.56] {
            let startFrame = Int(start * sampleRate)
            let knockFrames = Int(0.15 * sampleRate)
            var phase = 0.0
            for i in 0..<knockFrames where startFrame + i < total {
                let t = Double(i) / sampleRate
                let freq = 170.0 * pow(55.0 / 170.0, min(t / 0.09, 1.0))
                phase += 2.0 * .pi * freq / sampleRate
                let envelope = Float(0.9 * exp(-t / 0.045))
                samples[startFrame + i] += Float(sin(phase)) * envelope
            }
        }
        return buffer
    }

    /// 삐- 삐- 삐- 알림음
    private func beepBuffer() -> AVAudioPCMBuffer? {
        guard let buffer = emptyBuffer(duration: 0.95) else { return nil }
        let samples = buffer.floatChannelData![0]
        let total = Int(buffer.frameLength)
        for start in [0.0, 0.3, 0.6] {
            let startFrame = Int(start * sampleRate)
            let beepFrames = Int(0.22 * sampleRate)
            for i in 0..<beepFrames where startFrame + i < total {
                let t = Double(i) / sampleRate
                let envelope = Float(0.4 * exp(-t / 0.08))
                samples[startFrame + i] += Float(sin(2.0 * .pi * 880.0 * t)) * envelope
            }
        }
        return buffer
    }
}
