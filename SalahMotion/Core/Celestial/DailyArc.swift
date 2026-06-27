import Foundation

// MARK: - DailyArc
//
// Pure mapping from a wall instant to a daily-arc phase [0,1), given a body's
// rise / transit / set for the day plus the neighbouring crossings that close the
// night. Shared by any body (Sun today; Moon once SwiftAA lands).
//
//   rise    → 0.00   (left corner / horizon)
//   transit → 0.25   (peak)
//   set     → 0.50   (right corner / horizon)
//   night   → 0.50…1.0  (below horizon; exact nadir timing is cosmetic, so linear)

enum DailyArc {

    static func phase(now: Date,
                      previousSet: Date?,
                      rise: Date,
                      transit: Date,
                      set: Date,
                      nextRise: Date?) -> Double {
        if now < rise {
            // Night that began at the previous set, climbing toward this rise.
            guard let previousSet else { return 0.75 }
            return 0.5 + 0.5 * fraction(now, from: previousSet, to: rise)
        }
        if now < transit {
            return 0.25 * fraction(now, from: rise, to: transit)
        }
        if now <= set {
            // Inclusive of the set instant so the crossing lands exactly on 0.5.
            return 0.25 + 0.25 * fraction(now, from: transit, to: set)
        }
        // Night after set, descending toward the next rise.
        guard let nextRise else { return 0.75 }
        return 0.5 + 0.5 * fraction(now, from: set, to: nextRise)
    }

    private static func fraction(_ t: Date, from a: Date, to b: Date) -> Double {
        let span = b.timeIntervalSince(a)
        guard span > 0 else { return 0 }
        return min(max(t.timeIntervalSince(a) / span, 0), 1)
    }
}
