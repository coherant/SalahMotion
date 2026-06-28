import SwiftUI

// MARK: - NightMeteorsView
//
// A view-only ambient layer: a rare shooting star streaks across the night sky —
// the night counterpart to the daytime birds. Spec: docs/features/prayer-times/
// night-meteors.md.
//
// A meteor is NOT astronomy (an individual shooting star is unpredictable), so it
// is a cosmetic event on a random timer. Position is a pure function of `now`
// (same discipline as the birds/celestial), stepped by a `TimelineView`. Tier 2
// (meteor-shower awareness) only swaps the spawn DIRECTION for the projected
// radiant — the model below already takes a direction.

enum MeteorConfig {
    /// Master flag — `false` short-circuits to nothing (no timeline, no cost).
    static let isEnabled = true

    /// Seconds between meteors (randomized in this range). Rare by design.
    static let spawnGap: ClosedRange<Double> = 28...75
    /// Screen-heights travelled per second (a streak crosses in ~1 s).
    static let speed: ClosedRange<Double> = 0.7...1.1
    /// Lifetime of one streak (s).
    static let lifetime: ClosedRange<Double> = 0.8...1.4
    /// Trail length as a fraction of screen height.
    static let trailLength: CGFloat = 0.14
    static let trailSegments = 8
    static let headRadius: CGFloat = 1.6
    /// Peak opacity (faint — it's far). Scaled by the night factor.
    static let opacity: Double = 0.9
    /// Downward lean off horizontal (radians) — shallow, so meteors streak ACROSS
    /// the upper sky and leave the screen in roughly the top half, not dive down.
    static let descent: ClosedRange<Double> = 0.05...0.22
}

// MARK: - Meteor (pure function of time)

private struct Meteor {
    let spawn: Date
    let start: CGPoint        // normalized 0…1 (upper sky)
    let dir: SIMD2<Double>    // unit travel direction (Tier 2 sets this from a radiant)
    let speed: Double         // screen-heights / second
    let life: Double          // seconds

    func age(at date: Date) -> Double { date.timeIntervalSince(spawn) }

    /// Head position in points; travels start → along `dir`.
    func head(at date: Date, in size: CGSize) -> CGPoint {
        let d = age(at: date) * speed * Double(size.height)
        return CGPoint(x: start.x * size.width + CGFloat(dir.x * d),
                       y: start.y * size.height + CGFloat(dir.y * d))
    }

    /// 0 at birth → 1 mid-life → 0 at death, so it fades in and out (never pops).
    func brightness(at date: Date) -> Double {
        let t = min(max(age(at: date) / life, 0), 1)
        return sin(.pi * t)
    }
}

// MARK: - Shower context (Tier 2)

/// Resolved by the host (PrayerTimesView) from the date + egg + SwiftAA radiant
/// position. `radiant` non-nil ⇒ shower mode: streaks emanate from that screen
/// point and spawn `rate`× faster. nil ⇒ ordinary sporadic meteors.
struct MeteorShowerContext: Equatable {
    var radiant: CGPoint?
    var rate: Double
    static let none = MeteorShowerContext(radiant: nil, rate: 1)
}

// MARK: - MeteorField (reference type)
//
// Held in @State and mutated INSIDE the Canvas — being a class, those mutations
// are invisible to SwiftUI (no "modifying state during view update"); the redraw
// is driven by the TimelineView. (A @State value-type array mutated mid-draw is
// silently dropped — that was the original "nothing shows" bug.)

private final class MeteorField {
    var meteors: [Meteor] = []
    private var nextSpawn: Date = .distantPast

    func advance(to date: Date, night: Double, shower: MeteorShowerContext) {
        meteors.removeAll { $0.age(at: date) > $0.life }

        guard date >= nextSpawn else { return }
        // Shower mode spawns `rate`× faster.
        nextSpawn = date.addingTimeInterval(Double.random(in: MeteorConfig.spawnGap) / max(1, shower.rate))
        guard night >= 0.5 else { return }      // only when it's dark
        if let radiant = shower.radiant {
            meteors.append(Self.makeRadiant(at: date, radiant: radiant))
        } else {
            meteors.append(Self.make(at: date))
        }
    }

    /// Tier 1: start in the upper sky and streak near-horizontally across it, with a
    /// shallow downward lean — entering from one side, leaving the other, staying in
    /// roughly the top half. (Tier 2 replaces this direction with the projected
    /// shower radiant.)
    private static func make(at date: Date) -> Meteor {
        let goingRight = Bool.random()
        let descent = Double.random(in: MeteorConfig.descent)
        let angle = goingRight ? descent : (Double.pi - descent)   // ~horizontal ± shallow lean
        let dir = SIMD2(cos(angle), sin(angle))
        let start = CGPoint(x: goingRight ? CGFloat.random(in: 0.0...0.35)
                                          : CGFloat.random(in: 0.65...1.0),
                            y: CGFloat.random(in: 0.05...0.30))
        return Meteor(spawn: date, start: start, dir: dir,
                      speed: .random(in: MeteorConfig.speed),
                      life: .random(in: MeteorConfig.lifetime))
    }

    /// Shower meteor: appears just out from the radiant and streaks AWAY from it,
    /// so the whole shower visibly emanates from one point.
    private static func makeRadiant(at date: Date, radiant: CGPoint) -> Meteor {
        let theta = Double.random(in: 0...(2 * .pi))
        let dir = SIMD2(cos(theta), sin(theta))
        let offset = CGFloat.random(in: 0.03...0.18)
        let start = CGPoint(x: radiant.x + CGFloat(dir.x) * offset,
                            y: radiant.y + CGFloat(dir.y) * offset)
        return Meteor(spawn: date, start: start, dir: dir,
                      speed: .random(in: MeteorConfig.speed),
                      life: .random(in: MeteorConfig.lifetime))
    }
}

// MARK: - NightMeteorsView

struct NightMeteorsView: View {
    /// Tick only while foreground & on this tab (paused otherwise).
    var isActive: Bool
    /// 0…1 darkness (1 = deep night). Gates spawning and scales opacity, so meteors
    /// fade in as the sky darkens and never show in daylight.
    var night: Double
    /// Streak tint — pass the theme's star/ink colour for cohesion.
    var tint: Color
    /// Shower context (date- or egg-driven); `.none` = ordinary sporadic meteors.
    var shower: MeteorShowerContext = .none

    @State private var field = MeteorField()

    var body: some View {
        if MeteorConfig.isEnabled {
            TimelineView(.animation(paused: !isActive)) { timeline in
                Canvas { ctx, size in
                    field.advance(to: timeline.date, night: night, shower: shower)
                    draw(in: ctx, size: size, at: timeline.date)
                }
            }
            .allowsHitTesting(false)
        }
    }

    // MARK: Render — bright head + tapering, fading trail

    private func draw(in ctx: GraphicsContext, size: CGSize, at date: Date) {
        for meteor in field.meteors {
            let brightness = meteor.brightness(at: date) * night * MeteorConfig.opacity
            guard brightness > 0.01 else { continue }

            let head = meteor.head(at: date, in: size)
            let trailEnd = CGPoint(
                x: head.x - CGFloat(meteor.dir.x) * MeteorConfig.trailLength * size.height,
                y: head.y - CGFloat(meteor.dir.y) * MeteorConfig.trailLength * size.height)

            // Trail: segments from head back, opacity and width tapering to nothing.
            let segs = MeteorConfig.trailSegments
            for s in 0..<segs {
                let t0 = Double(s) / Double(segs)
                let t1 = Double(s + 1) / Double(segs)
                var path = Path()
                path.move(to: lerp(head, trailEnd, t0))
                path.addLine(to: lerp(head, trailEnd, t1))
                let width = max(0.4, MeteorConfig.headRadius * 1.6 * CGFloat(1 - t0))
                ctx.stroke(path, with: .color(tint.opacity(brightness * (1 - t0))),
                           style: StrokeStyle(lineWidth: width, lineCap: .round))
            }

            // Head: soft glow + bright core.
            let r = MeteorConfig.headRadius
            ctx.fill(Path(ellipseIn: CGRect(x: head.x - r * 2.2, y: head.y - r * 2.2,
                                            width: r * 4.4, height: r * 4.4)),
                     with: .color(tint.opacity(brightness * 0.25)))
            ctx.fill(Path(ellipseIn: CGRect(x: head.x - r, y: head.y - r,
                                            width: r * 2, height: r * 2)),
                     with: .color(tint.opacity(min(1, brightness * 1.2))))
        }
    }

    private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * CGFloat(t), y: a.y + (b.y - a.y) * CGFloat(t))
    }
}
