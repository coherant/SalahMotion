import AVFoundation

@Observable
final class AudioManager {
    private(set) var isSpeaking: Bool = false

    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()
    nonisolated(unsafe) private let delegate    = SpeechFinishDelegate()

    init() { synthesizer.delegate = delegate }

    func configure(route: AudioRoute) {
        var options: AVAudioSession.CategoryOptions = .duckOthers
        if route == .speakerOnly { options.insert(.defaultToSpeaker) }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: options)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    @MainActor
    func speak(_ text: String, language: Language = UserPreferences.shared.language) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            isSpeaking = true
            delegate.onFinish = { [weak self] in
                self?.isSpeaking = false
                cont.resume()
            }
            let u = AVSpeechUtterance(string: text)
            u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
            u.voice = AVSpeechSynthesisVoice(language: language.voiceCode)
            synthesizer.speak(u)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

private final class SpeechFinishDelegate: NSObject, AVSpeechSynthesizerDelegate {
    nonisolated(unsafe) var onFinish: (() -> Void)?

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let fn = onFinish; onFinish = nil; fn?()
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let fn = onFinish; onFinish = nil; fn?()
    }
}
