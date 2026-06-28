import Foundation
import Observation
import QuartzCore

// MARK: - Time-machine egg (hidden)
//
// A purely VISUAL rewind: it drives a `offset` added to "now" for the time-
// reactive UI (theme + celestial), animating 0 → −N days → 0 with an
// accelerate-then-decelerate curve, then snapping back. It never mutates the
// prayer engine or reschedules notifications — read-only illusion only.

/// ── TUNABLES ───────────────────────────────────────────────────────────────
/// Adjust these to dial in the animation. `legDuration` is the one-number speed
/// knob; the two weights set the accel/decel feel (only their ratio matters).
enum TimeMachineConfig {
    /// How far back the rewind travels, in days.
    static var daysBack: Double = 1

    /// Seconds for ONE direction (back, or forward). Round-trip = 2 × this.
    /// ← the main "speed" knob.
    static var legDuration: TimeInterval = 10

    /// Shape of each leg: time spent accelerating vs decelerating to a stop.
    /// Relative weights (your "3 accelerate, 2 decelerate") — only the ratio counts.
    static var accelerateWeight: Double = 3
    static var decelerateWeight: Double = 2

    /// Egg stage 2: how long the murmuration swirls before it streams off (s).
    static var murmurationDuration: TimeInterval = 40

    /// Egg stage 3: how long the on-demand meteor shower runs (s).
    static var meteorShowerDuration: TimeInterval = 40

    /// Egg stage 4: how long the on-demand aurora lingers (s).
    static var auroraDuration: TimeInterval = 28

    /// When true, every egg press goes straight to the murmuration, skipping the
    /// celestial sweep (used while tuning the flock). False = the two-stage egg.
    static var eggOnlyMurmuration = false
}

@MainActor
@Observable
final class TimeMachine {
    static let shared = TimeMachine()
    private init() {}

    /// Seconds added to "now" for all time-reactive UI. 0 = real time.
    private(set) var offset: TimeInterval = 0
    private(set) var isRunning = false
    /// Egg stage 2: true while the hidden murmuration is dancing. The birds layer
    /// observes this and floods in / disperses on its edges.
    private(set) var murmurationActive = false
    /// Egg stage 3: true while the on-demand meteor shower runs. The meteor layer
    /// observes this and forces shower mode regardless of the date.
    private(set) var meteorShowerActive = false
    /// Egg stage 4: true while the on-demand aurora lingers.
    private(set) var auroraActive = false

    private var task: Task<Void, Never>?
    // Celestial sweep is driven by a CADisplayLink (vsync-aligned) — NOT a
    // `Task.sleep` timer, whose imprecise, unsynced ~16 ms steps beat against the
    // display refresh and made the sweep stutter (worse under any main-thread load).
    private var displayLink: CADisplayLink?
    private var linkProxy: DisplayLinkProxy?
    private var celestialStart: CFTimeInterval = 0   // 0 = set on first frame

    /// The egg is a four-press secret: press 1 sweeps the sky (celestial rewind),
    /// press 2 summons the murmuration, press 3 calls a meteor shower, press 4 an
    /// aurora. Each press advances the stage; a press is ignored while any is playing.
    private enum Stage { case celestial, birds, meteor, aurora }
    private var nextStage: Stage = .celestial

    func play() {
        guard !isRunning, !murmurationActive, !meteorShowerActive, !auroraActive else { return }
        if TimeMachineConfig.eggOnlyMurmuration {   // TEMP: tuning the murmuration
            playBirds()
            return
        }
        switch nextStage {
        case .celestial:
            nextStage = .birds
            playCelestial()
        case .birds:
            nextStage = .meteor
            playBirds()
        case .meteor:
            nextStage = .aurora
            playMeteorShower()
        case .aurora:
            nextStage = .celestial
            playAurora()
        }
    }

    /// Stage 1 — the round-trip time rewind (back then forward), advanced once per
    /// display refresh so `offset` moves in lockstep with what's on screen.
    private func playCelestial() {
        isRunning = true
        offset = 0
        celestialStart = 0

        let proxy = DisplayLinkProxy { [weak self] link in
            MainActor.assumeIsolated { self?.tickCelestial(link) }   // CADisplayLink fires on .main
        }
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.step(_:)))
        link.add(to: .main, forMode: .common)
        linkProxy = proxy
        displayLink = link
    }

    private func tickCelestial(_ link: CADisplayLink) {
        if celestialStart == 0 { celestialStart = link.timestamp }
        let elapsed = link.timestamp - celestialStart
        let leg = TimeMachineConfig.legDuration
        let total = leg * 2
        let maxBack = -TimeMachineConfig.daysBack * 86_400

        guard elapsed < total else {
            offset = 0
            isRunning = false
            stopCelestialLink()
            return
        }
        offset = Self.offset(forElapsed: elapsed, leg: leg, maxBack: maxBack)
    }

    private func stopCelestialLink() {
        displayLink?.invalidate()
        displayLink = nil
        linkProxy = nil
        celestialStart = 0
    }

    /// Stage 2 — flag the murmuration window; the birds layer owns the visuals.
    private func playBirds() {
        murmurationActive = true
        task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(TimeMachineConfig.murmurationDuration * 1_000_000_000))
            murmurationActive = false
        }
    }

    /// Stage 3 — flag the meteor-shower window; the meteor layer owns the visuals.
    private func playMeteorShower() {
        meteorShowerActive = true
        task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(TimeMachineConfig.meteorShowerDuration * 1_000_000_000))
            meteorShowerActive = false
        }
    }

    /// Stage 4 — flag the aurora window; the aurora layer owns the visuals.
    private func playAurora() {
        auroraActive = true
        task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(TimeMachineConfig.auroraDuration * 1_000_000_000))
            auroraActive = false
        }
    }

    // MARK: - Curve

    private static func offset(forElapsed elapsed: TimeInterval,
                               leg: TimeInterval, maxBack: Double) -> TimeInterval {
        if elapsed < leg {
            return maxBack * ease(elapsed / leg)              // 0 → maxBack
        } else {
            return maxBack * (1 - ease((elapsed - leg) / leg)) // maxBack → 0
        }
    }

    /// Accelerate-then-decelerate easing with a tunable split — the integral of a
    /// triangular velocity profile that peaks at `a` and returns to rest at 1.
    /// ease(0)=0, ease(1)=1.
    private static func ease(_ p: Double) -> Double {
        let total = TimeMachineConfig.accelerateWeight + TimeMachineConfig.decelerateWeight
        let a = max(0.001, min(0.999, TimeMachineConfig.accelerateWeight / total))
        if p <= a {
            return (p * p) / a
        } else {
            return a + 2.0 / (1 - a) * ((p - p * p / 2) - (a - a * a / 2))
        }
    }
}

// MARK: - CADisplayLink → closure bridge
//
// CADisplayLink needs an @objc selector target; this lets `TimeMachine` stay a
// plain @Observable class instead of an NSObject. Fires on the main runloop, so
// the handler safely assumes main-actor isolation.
private final class DisplayLinkProxy: NSObject {
    private let onFrame: (CADisplayLink) -> Void
    init(_ onFrame: @escaping (CADisplayLink) -> Void) {
        self.onFrame = onFrame
        super.init()
    }
    @objc func step(_ link: CADisplayLink) { onFrame(link) }
}
