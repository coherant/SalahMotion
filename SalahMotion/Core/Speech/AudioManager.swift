import AVFoundation

@Observable
final class AudioManager {
    private(set) var isSpeaking: Bool = false

    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()
    nonisolated(unsafe) private let delegate    = SpeechFinishDelegate()
    nonisolated(unsafe) private var player: AVAudioPlayer?
    nonisolated(unsafe) private let playerDelegate = PlayerFinishDelegate()

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

    /// Plays a recorded recitation, awaited to completion — the teacher leads, so the clip is
    /// never truncated by the caller's `.pace` pause regardless of length. Returns `false` if
    /// the file can't be loaded/started so the caller can fall back to TTS.
    @MainActor
    @discardableResult
    func play(_ url: URL) async -> Bool {
        guard let p = try? AVAudioPlayer(contentsOf: url) else { return false }
        player = p
        p.delegate = playerDelegate
        return await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            isSpeaking = true
            playerDelegate.onFinish = { [weak self] in
                self?.isSpeaking = false
                cont.resume(returning: true)
            }
            if !p.play() {
                isSpeaking = false
                playerDelegate.onFinish = nil
                cont.resume(returning: false)
            }
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        player?.stop()
    }
}

// MARK: - Recitation clips
//
// Resolves a recitation id to a bundled recording, or nil when none is installed (→ TTS
// fallback). Convention: `recitations/<reciterId>/<P-id>.m4a` (e.g. recitations/bilal/P-7.m4a).
// Add the `recitations` folder to the app target as a FOLDER REFERENCE so the per-reciter
// subdirectories are preserved in the bundle. Missing clips are expected — drop files in
// incrementally and partial sets just work.
enum RecitationClips {
    /// Active reciter folder. Defaults until a reciter preference is wired to the picker.
    static var reciterId: String = "default"

    static func url(for id: PrayerID, reciterId: String = RecitationClips.reciterId) -> URL? {
        Bundle.main.url(forResource: id.rawValue,
                        withExtension: "m4a",
                        subdirectory: "recitations/\(reciterId)")
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

private final class PlayerFinishDelegate: NSObject, AVAudioPlayerDelegate {
    nonisolated(unsafe) var onFinish: (() -> Void)?

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let fn = onFinish; onFinish = nil; fn?()
    }
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let fn = onFinish; onFinish = nil; fn?()
    }
}
