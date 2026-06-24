import Foundation
import Observation

// MARK: - Prayer calculation settings
// Source of truth: docs/features/settings/SPEC.md §2 (Advanced)
//
// User-configurable inputs to the prayer-time engine. Persisted to UserDefaults.
// The Advanced settings screen binds directly to these values; PrayerTimesEngine
// reads them when it (re)computes. Changing any value triggers a recompute.

@Observable
final class PrayerCalculationSettings {
    static let shared = PrayerCalculationSettings()

    /// Calculation method (angles/intervals) — e.g. Muslim World League, Karachi.
    var method: CalculationMethod {
        didSet {
            UserDefaults.standard.set(method.rawValue, forKey: Keys.method)
            PrayerTimesEngine.shared.recompute()
        }
    }

    /// Asr shadow rule — `.shafi` (Standard) or `.hanafi`.
    var madhab: Madhab {
        didSet {
            UserDefaults.standard.set(madhab.rawValue, forKey: Keys.madhab)
            PrayerTimesEngine.shared.recompute()
        }
    }

    /// Per-prayer minute offsets (e.g. +2 to nudge Fajr later). Default 0.
    var offsets: [PrayerTime: Int] {
        didSet {
            persistOffsets()
            PrayerTimesEngine.shared.recompute()
        }
    }

    /// Day adjustment applied to the displayed Hijri date. Default 0.
    var hijriOffsetDays: Int {
        didSet { UserDefaults.standard.set(hijriOffsetDays, forKey: Keys.hijri) }
    }

    /// Adhan adjustments built from `offsets`. Sunrise is not user-adjustable here.
    var prayerAdjustments: PrayerAdjustments {
        PrayerAdjustments(
            fajr:    offsets[.fajr]    ?? 0,
            sunrise: 0,
            dhuhr:   offsets[.dhuhr]   ?? 0,
            asr:     offsets[.asr]     ?? 0,
            maghrib: offsets[.maghrib] ?? 0,
            isha:    offsets[.isha]    ?? 0
        )
    }

    private init() {
        let d = UserDefaults.standard
        method = CalculationMethod(rawValue: d.string(forKey: Keys.method) ?? "") ?? .muslimWorldLeague
        // integer(forKey:) returns 0 when unset; Madhab has no rawValue 0, so this
        // falls back to .shafi for a fresh install.
        madhab = Madhab(rawValue: d.integer(forKey: Keys.madhab)) ?? .shafi
        hijriOffsetDays = d.integer(forKey: Keys.hijri)

        let raw = d.dictionary(forKey: Keys.offsets) as? [String: Int] ?? [:]
        offsets = Dictionary(uniqueKeysWithValues: raw.compactMap { key, value in
            PrayerTime(rawValue: key).map { ($0, value) }
        })
    }

    private func persistOffsets() {
        let dict = Dictionary(uniqueKeysWithValues: offsets.map { ($0.key.rawValue, $0.value) })
        UserDefaults.standard.set(dict, forKey: Keys.offsets)
    }

    private enum Keys {
        static let method  = "prayerCalc.method"
        static let madhab  = "prayerCalc.madhab"
        static let offsets = "prayerCalc.offsets"
        static let hijri   = "prayerCalc.hijriOffsetDays"
    }
}
