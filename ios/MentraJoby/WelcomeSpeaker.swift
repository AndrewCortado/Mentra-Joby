import AVFoundation
import Foundation

protocol WelcomeSpeaking: AnyObject {
    func speak(_ text: String)
}

final class WelcomeSpeaker: NSObject, WelcomeSpeaking, AVSpeechSynthesizerDelegate {
    var onPlayingChanged: (Bool) -> Void
    var onFinished: () -> Void

    private let synthesizer = AVSpeechSynthesizer()

    init(
        onPlayingChanged: @escaping (Bool) -> Void = { _ in },
        onFinished: @escaping () -> Void = {}
    ) {
        self.onPlayingChanged = onPlayingChanged
        self.onFinished = onFinished
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            onFinished()
            return
        }
        onPlayingChanged(true)
        synthesizer.speak(AVSpeechUtterance(string: text))
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        onPlayingChanged(false)
        onFinished()
    }

    func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) {
        onPlayingChanged(false)
        onFinished()
    }
}

enum AudioRoute {
    static func currentIsBluetooth() -> Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains { output in
            output.portType == .bluetoothA2DP
                || output.portType == .bluetoothHFP
                || output.portType == .bluetoothLE
        }
    }
}
