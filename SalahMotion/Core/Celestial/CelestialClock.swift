import Foundation

// MARK: - CelestialClock
//
// Decouples "what instant do we evaluate" from view timing. Because every body's
// position is a pure function of this instant, there is no animation state to
// pause/resume — leaving a screen and returning just re-evaluates the clock.
//
//   • .realtime          — production: the instant IS now.
//   • .demo(secondsPerDay:) — concept: a full reference day sweeps every N seconds.
//
// Crucially, demo maps wall-clock → instant statelessly (no accumulating counter),
// so returning mid-loop is continuous and correct.

enum CelestialClock: Equatable {
    case realtime
    case demo(secondsPerDay: TimeInterval)

    func evaluationDate(for wallClock: Date) -> Date {
        switch self {
        case .realtime:
            return wallClock
        case .demo(let secondsPerDay):
            guard secondsPerDay > 0 else { return wallClock }
            let fraction = wallClock.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: secondsPerDay) / secondsPerDay
            let dayStart = Calendar.gregorianUTC.startOfDay(for: wallClock)
            return dayStart.addingTimeInterval(fraction * 86_400)
        }
    }
}
