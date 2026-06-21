import CoreMotion

@Observable
final class HeadphoneMotionDetector {
    private(set) var smoothedPitch: Double = 0
    private(set) var smoothedRoll:  Double = 0
    private(set) var smoothedYaw:   Double = 0

    var isAvailable: Bool { manager.isDeviceMotionAvailable }

    nonisolated(unsafe) private let manager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()
    private var readings = SensorReadings()

    func start(onRawSample: (@Sendable (Double, Double, Double) -> Void)? = nil) {
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let motion else { return }
            let p = motion.attitude.pitch * 180 / .pi
            let r = motion.attitude.roll  * 180 / .pi
            let y = motion.attitude.yaw   * 180 / .pi
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.readings.add(pitch: p, roll: r, yaw: y)
                self.smoothedPitch = self.readings.smoothedPitch
                self.smoothedRoll  = self.readings.smoothedRoll
                self.smoothedYaw   = self.readings.smoothedYaw
                onRawSample?(p, r, y)
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
