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

// MARK: - Audio clips
//
// Resolves a liturgical id to a bundled recording, or nil when none is installed (→ TTS
// fallback). Files are FLAT, uniquely-named resources — so synced-folder flattening is a
// feature, not a problem (no subfolders to preserve, no name collisions):
//   • in-salah recitation:  "<reciterId>-<language>-<P-id>.m4a"  (e.g. sawt-ai-ar-P-7.m4a)
//   • Muezzin call:          "<muezzinId>-<C-id>.m4a"            (e.g. bilal-C-1.m4a)
// Drop the files anywhere under the app's synced Resources; they bundle by name. Either
// .m4a or .caf is accepted (Ṣawt AI ships as .m4a, AAC). Missing clips are expected —
// partial sets just work, and anything absent falls back to TTS.
enum AudioClips {
    /// Active reciter folder for in-salah recitation. Defaults until a reciter picker is wired.
    /// `sawt-ai` = "Ṣawt AI" — the AI-generated Arabic recitation voice (صوت = "voice").
    static var reciterId: String = "sawt-ai"

    static func recitation(_ id: PrayerID,
                           reciterId: String = AudioClips.reciterId,
                           language: Language = UserPreferences.shared.language) -> URL? {
        // Flat key "<reciter>-<language>-<P-id>" (e.g. "sawt-ai-ar-P-7"). Missing →
        // nil → the caller's TTS fallback, so an Arabic-only reciter still works when
        // any language is picked.
        clip("\(reciterId)-\(language.rawValue)-\(id.rawValue)")
    }

    static func call(_ id: CallID, muezzinId: String) -> URL? {
        clip("\(muezzinId)-\(id.rawValue)")
    }

    // Accept .m4a (the Ṣawt AI set) or .caf. Names are globally unique, so we look in
    // the bundle root AND the likely preserved subfolders — covers both a synced folder
    // that flattens resources and one that keeps the `recitations/` (or `muezzin/`) path.
    private static let clipExtensions = ["m4a", "caf"]
    private static let clipSubdirs: [String?] = [nil, "recitations", "muezzin", "Resources/recitations"]

    private static func clip(_ name: String) -> URL? {
        for sub in clipSubdirs {
            for ext in clipExtensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub) {
                    return url
                }
            }
        }
        return nil
    }

#if DEBUG
    /// One-shot console report of which recitation/call clips are installed vs missing —
    /// printed at session start so populating the audio files is a matter of reading the list.
    static func logCoverage(muezzinId: String) {
        let recMissing  = PrayerID.allCases.filter { recitation($0) == nil }.map(\.rawValue)
        let callMissing = CallID.allCases.filter { call($0, muezzinId: muezzinId) == nil }.map(\.rawValue)
        let recHave  = PrayerID.allCases.count - recMissing.count
        let callHave = CallID.allCases.count - callMissing.count
        print("[AudioClips] recitations (\(reciterId)): \(recHave)/\(PrayerID.allCases.count)"
              + (recMissing.isEmpty ? " ✅ all installed" : " — missing: \(recMissing.joined(separator: ", "))"))
        print("[AudioClips] muezzin (\(muezzinId)): \(callHave)/\(CallID.allCases.count)"
              + (callMissing.isEmpty ? " ✅ all installed" : " — missing: \(callMissing.joined(separator: ", "))"))
    }
#endif
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
