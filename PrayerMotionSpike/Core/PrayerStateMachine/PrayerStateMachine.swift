import Foundation
import AVFoundation
import AudioToolbox
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Audio route (source: docs/global-configurations.md)

enum AudioRoute {
    case speakerOnly  // forces built-in speaker even when AirPods connected
    case headphones   // routes to AirPods if connected, speaker otherwise (default)
    case auto         // iOS decides — same as headphones in practice
}

// MARK: - Session sample

struct SessionSample {
    let timestamp: Double
    let stateID: String
    let pitch: Double
    let roll: Double
    let yaw: Double
}

// MARK: - State Machine

@Observable
final class PrayerStateMachine {

    enum Status: Equatable { case idle, running, complete, cancelled }

    private(set) var status: Status = .idle
    private(set) var currentStateIndex: Int = 0
    private(set) var states: [PrayerState]
    private(set) var confirmProgress: Double = 0
    private(set) var pitch: Double = 0
    private(set) var roll:  Double = 0
    private(set) var yaw:   Double = 0

    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()
    private let speechDelegate = PrayerSpeechDelegate()

    private let detector       = HeadphoneMotionDetector()
    private var thresholds: MotionThresholds

    private var qiyamYawBaseline: Double? = nil
    private var sessionTask: Task<Void, Never>?
    private(set) var sessionSamples: [SessionSample] = []
    private var sessionStartDate: Date?
    private let participantName: String
    private let audioRoute: AudioRoute
    private let holdWindow: Double = 1.5

    var isAvailable: Bool { detector.isAvailable }
    var currentState: PrayerState { states[currentStateIndex] }

    init(sequence: [PrayerState] = PrayerSequenceGenerator.generate(),
         participantName: String = "",
         audioRoute: AudioRoute = .headphones) {
        states = sequence
        self.participantName = participantName
        self.audioRoute = audioRoute
        self.thresholds = MotionThresholds(profile: UserCalibrationProfile.load())
        synthesizer.delegate = speechDelegate
    }

    func start() {
        guard isAvailable, status == .idle else { return }
        configureAudioSession()
#if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = true
#endif
        sessionSamples = []
        sessionStartDate = Date()
        qiyamYawBaseline = nil
        startMotionUpdates()
        status = .running
        sessionTask = Task { [weak self] in await self?.runStateMachine() }
    }

    func cancel() {
        sessionTask?.cancel()
        synthesizer.stopSpeaking(at: .immediate)
        detector.stop()
#if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = false
#endif
        status = .cancelled
    }

    // MARK: - Motion updates

    private func startMotionUpdates() {
        detector.start { [weak self] p, r, y in
            guard let self else { return }
            self.pitch = self.detector.smoothedPitch
            self.roll  = self.detector.smoothedRoll
            self.yaw   = self.detector.smoothedYaw
            let elapsed = Date().timeIntervalSince(self.sessionStartDate ?? Date())
            let stateID = self.states[self.currentStateIndex].id.rawValue
            self.sessionSamples.append(SessionSample(
                timestamp: elapsed, stateID: stateID, pitch: p, roll: r, yaw: y
            ))
        }
    }

    // MARK: - State machine loop

    @MainActor
    private func runStateMachine() async {
        let sessionStart = Date()

        for (index, state) in states.enumerated() {
            guard !Task.isCancelled else { break }
            currentStateIndex = index
            print(String(format: "[PrayerSM] ▶ %d/%d %@ (%@) t=%.1fs",
                         index + 1, states.count, state.id.rawValue, state.mode.rawValue,
                         Date().timeIntervalSince(sessionStart)))

            switch state.mode {
            case .auto:        await runAutoPhase(state)
            case .timed:       await runTimedPhase(state)
            case .motion:      await runMotionPhase(state)
            case .timedMotion: await runTimedMotionPhase(state)
            }

            if state.capturesYawBaseline {
                qiyamYawBaseline = yaw
                print(String(format: "[PrayerSM] 📐 Yaw baseline: %.1f° (%@)",
                             qiyamYawBaseline!, state.id.rawValue))
            }
        }

        detector.stop()
#if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = false
#endif
        if !Task.isCancelled {
            saveSession()
            status = .complete
        }
        print("[PrayerSM] ✅ Session ended — status: \(status)")
    }

    // MARK: - Phase runners

    @MainActor
    private func runAutoPhase(_ state: PrayerState) async {
        if let speech = state.entrySpeech { await speak(speech) }
        for prayer in state.prayers {
            guard !Task.isCancelled else { return }
            if !prayer.utterance.isEmpty { await speak(prayer.utterance) }
            guard !Task.isCancelled else { return }
            if prayer.duration > 0 { try? await Task.sleep(for: .seconds(prayer.duration)) }
        }
        guard !Task.isCancelled else { return }
        if let speech = state.exitSpeech { await speak(speech) }
    }

    @MainActor
    private func runTimedPhase(_ state: PrayerState) async {
        if let speech = state.entrySpeech { await speak(speech) }
        guard !Task.isCancelled else { return }
        if !state.prayers.isEmpty { AudioServicesPlaySystemSound(1108) }
        for prayer in state.prayers {
            guard !Task.isCancelled else { return }
            if !prayer.utterance.isEmpty { await speak(prayer.utterance) }
            guard !Task.isCancelled else { return }
            if prayer.duration > 0 {
                let start = Date()
                while !Task.isCancelled {
                    let elapsed = Date().timeIntervalSince(start)
                    confirmProgress = min(elapsed / prayer.duration, 1.0)
                    if elapsed >= prayer.duration { break }
                    try? await Task.sleep(for: .milliseconds(50))
                }
                confirmProgress = 0
            }
        }
        guard !Task.isCancelled else { return }
        if let speech = state.exitSpeech { await speak(speech) }
    }

    @MainActor
    private func runMotionPhase(_ state: PrayerState) async {
        if let speech = state.entrySpeech { await speak(speech) }
        guard !Task.isCancelled else { return }
        await waitForMotion(state)
        guard !Task.isCancelled else { return }
        for prayer in state.prayers {
            guard !Task.isCancelled else { return }
            if !prayer.utterance.isEmpty { await speak(prayer.utterance) }
            guard !Task.isCancelled else { return }
            if prayer.duration > 0 { try? await Task.sleep(for: .seconds(prayer.duration)) }
        }
        guard !Task.isCancelled else { return }
        if let speech = state.exitSpeech { await speak(speech) }
    }

    @MainActor
    private func runTimedMotionPhase(_ state: PrayerState) async {
        if let speech = state.entrySpeech { await speak(speech) }
        guard !Task.isCancelled else { return }
        if !state.prayers.isEmpty { AudioServicesPlaySystemSound(1108) }

        var motionHoldStart: Date? = nil
        var lastRepromptAt = Date()

        for prayer in state.prayers {
            guard !Task.isCancelled else { return }
            if !prayer.utterance.isEmpty { await speak(prayer.utterance) }
            guard !Task.isCancelled else { return }

            if prayer.duration > 0 {
                let prayerStart = Date()
                while !Task.isCancelled {
                    let elapsed = Date().timeIntervalSince(prayerStart)
                    confirmProgress = min(elapsed / prayer.duration, 1.0)
                    if elapsed >= prayer.duration { break }

                    if let trigger = state.motionTrigger {
                        if thresholds.isSatisfied(trigger, pitch: pitch, roll: roll, yaw: yaw,
                                                  yawBaseline: qiyamYawBaseline) {
                            if motionHoldStart == nil {
                                motionHoldStart = Date()
                                print(String(format: "[PrayerSM] ◌ Motion: %@ p:%.1f° r:%.1f°",
                                             state.id.rawValue, pitch, roll))
                            }
                            let held = Date().timeIntervalSince(motionHoldStart!)
                            if held >= holdWindow {
                                print(String(format: "[PrayerSM] ✓ Confirmed: %@ held=%.2fs",
                                             state.id.rawValue, held))
                            }
                        } else {
                            motionHoldStart = nil
                        }

                        if Date().timeIntervalSince(lastRepromptAt) >= state.repromptInterval,
                           let reprompt = state.repromptAudio,
                           motionHoldStart == nil {
                            print("[PrayerSM] ⏰ Reprompt: \(state.id.rawValue)")
                            await speak(reprompt)
                            lastRepromptAt = Date()
                        }
                    }

                    try? await Task.sleep(for: .milliseconds(50))
                }
                confirmProgress = 0
            }
        }

        guard !Task.isCancelled else { return }
        if let speech = state.exitSpeech { await speak(speech) }
    }

    // MARK: - Motion waiting (used by .motion mode)

    @MainActor
    private func waitForMotion(_ state: PrayerState) async {
        guard let trigger = state.motionTrigger else { return }
        var holdStart: Date? = nil
        var lastRepromptAt = Date()

        while !Task.isCancelled {
            if thresholds.isSatisfied(trigger, pitch: pitch, roll: roll, yaw: yaw,
                                      yawBaseline: qiyamYawBaseline) {
                if holdStart == nil { holdStart = Date() }
                let held = Date().timeIntervalSince(holdStart!)
                confirmProgress = min(held / holdWindow, 1.0)

                if held >= holdWindow {
                    print(String(format: "[PrayerSM] ✓ Motion confirmed: %@ held=%.2fs",
                                 state.id.rawValue, held))
                    confirmProgress = 0
                    return
                }
            } else {
                holdStart = nil
                confirmProgress = 0

                if Date().timeIntervalSince(lastRepromptAt) >= state.repromptInterval,
                   let reprompt = state.repromptAudio {
                    print("[PrayerSM] ⏰ Reprompt: \(state.id.rawValue)")
                    await speak(reprompt)
                    lastRepromptAt = Date()
                }
            }

            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    // MARK: - Session saving

    private func saveSession() {
        guard !sessionSamples.isEmpty else { return }
        let isCalibration = !participantName.isEmpty
        let filename: String
        var lines: [String]

        if isCalibration {
            let slug = participantName
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: ",", with: "")
            filename = "prayer_calibration_\(slug)_\(Int(Date().timeIntervalSince1970)).csv"
            let csvName = participantName.replacingOccurrences(of: ",", with: "")
            lines = ["participant,timestamp_s,state_id,pitch_deg,roll_deg,yaw_deg"]
            for s in sessionSamples {
                lines.append(String(format: "%@,%.4f,%@,%.4f,%.4f,%.4f",
                                    csvName, s.timestamp, s.stateID, s.pitch, s.roll, s.yaw))
            }
        } else {
            filename = "prayer_session_\(Int(Date().timeIntervalSince1970)).csv"
            lines = ["timestamp_s,state_id,pitch_deg,roll_deg,yaw_deg"]
            for s in sessionSamples {
                lines.append(String(format: "%.4f,%@,%.4f,%.4f,%.4f",
                                    s.timestamp, s.stateID, s.pitch, s.roll, s.yaw))
            }
        }

        let csv = lines.joined(separator: "\n")
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("[PrayerSM] 💾 Saved: \(filename) (\(sessionSamples.count) samples)")
        } catch {
            print("[PrayerSM] ❌ Save failed: \(error)")
        }
    }

    // MARK: - Audio

    private func configureAudioSession() {
        var options: AVAudioSession.CategoryOptions = .duckOthers
        if audioRoute == .speakerOnly { options.insert(.defaultToSpeaker) }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: options)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    @MainActor
    private func speak(_ text: String) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            speechDelegate.onFinish = { cont.resume() }
            let u = AVSpeechUtterance(string: text)
            u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
            synthesizer.speak(u)
        }
    }
}

// MARK: - Speech delegate

private final class PrayerSpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
    nonisolated(unsafe) var onFinish: (() -> Void)?

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let fn = onFinish; onFinish = nil; fn?()
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let fn = onFinish; onFinish = nil; fn?()
    }
}
