import Foundation

// MARK: - Validated sensor behaviour (from real recording sessions)
//
// Ruku    — pitch is the primary signal (-73° to -75° observed). Highly distinct
//           from all other positions. Do not use roll as a gate for ruku.
//
// Sujood  — roll is the primary signal (~160–164°, roughly 180° away from all
//           other positions). Do NOT use pitch as the primary gate; it overlaps
//           too much with ruku. Use angular distance to handle Euler wraparound
//           near ±180° (e.g. a valid sujood can read as -178° not +178°).
//
// Upright — pitch alone cannot distinguish standing (Qiyam) from sitting (Julus);
//           both cluster at roughly -4° to -16°. Roll shows a small gap but it is
//           too thin to use as a hard threshold. Disambiguation MUST come from
//           sequence position (which upright state logically follows the last
//           confirmed motion), never from re-evaluating thresholds here.
//
// Yaw     — the CMHeadphoneMotionManager reference frame resets each session start,
//           so yaw values are not comparable across sessions. Tasleem detection
//           compares against a baseline the phase runner captures at the final sitting,
//           the instant before each unit's first Tasleem head-turn (after the unit's
//           sujoods, so the heading hasn't drifted). The 30° offset default has not yet
//           been validated with real data — tune after first live Tasleem test.

struct MotionThresholds {
    let profile: UserCalibrationProfile?

    func isSatisfied(
        _ trigger: MotionTrigger,
        pitch: Double,
        roll: Double,
        yaw: Double,
        yawBaseline: Double?
    ) -> Bool {
        switch trigger {
        case .ruku:
            return pitch >= (profile?.rukuPitchLow  ?? -90)
                && pitch <= (profile?.rukuPitchHigh ?? -30)

        case .sujood:
            // angDist handles Euler-angle wraparound; fallback radius calibrated at 88% coverage.
            return angularDistance(roll, 180) <= (profile?.sujoodRollRadius ?? 30)

        case .upright:
            // Roll is NOT a hard gate — sequence position disambiguates standing vs sitting.
            return pitch >= (profile?.uprightPitchLow  ?? -40)
                && pitch <= (profile?.uprightPitchHigh ?? 6)

        case .headTurnRight:
            guard let baseline = yawBaseline else { return false }
            return baseline - yaw >= (profile?.tasleemYawOffset ?? 30)

        case .headTurnLeft:
            guard let baseline = yawBaseline else { return false }
            return yaw - baseline >= (profile?.tasleemYawOffset ?? 30)
        }
    }

    func angularDistance(_ a: Double, _ b: Double) -> Double {
        let diff = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(diff, 360 - diff)
    }
}
