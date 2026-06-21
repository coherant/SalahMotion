import Foundation

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
            return pitch >= (profile?.rukuPitchLow  ?? -82)
                && pitch <= (profile?.rukuPitchHigh ?? -48)

        case .sujood:
            // angDist handles Euler-angle wraparound; fallback radius calibrated at 88% coverage.
            return angularDistance(roll, 180) <= (profile?.sujoodRollRadius ?? 35)

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
