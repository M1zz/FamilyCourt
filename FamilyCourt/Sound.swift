import AVFoundation
import UIKit

/// 의사봉(탕탕탕)과 타이머 종료음을 합성해서 재생해요.
final class SoundPlayer {

    static let shared = SoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    private init() {
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    func gavel() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        guard let buffer = gavelBuffer() else { return }
        play(buffer)
    }

    func beep() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        guard let buffer = beepBuffer() else { return }
        play(buffer)
    }

    private func play(_ buffer: AVAudioPCMBuffer) {
        try? AVAudioSession.sharedInstance().setActive(true)
        if !engine.isRunning { try? engine.start() }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
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
