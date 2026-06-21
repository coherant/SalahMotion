import Foundation

struct CalibrationAnalyzer {
    private let samples: [SessionSample]
    private let transitionDrop: Double = 1.5

    init(samples: [SessionSample]) {
        self.samples = samples
    }

    func analyze() -> UserCalibrationProfile? {
        let grouped = Dictionary(grouping: samples, by: { $0.stateID })

        func steady(for id: String) -> [SessionSample] {
            guard let group = grouped[id], !group.isEmpty else { return [] }
            let t0 = group.map { $0.timestamp }.min()!
            return group.filter { $0.timestamp - t0 >= transitionDrop }
        }

        func percentile(_ values: [Double], _ pct: Double) -> Double {
            guard !values.isEmpty else { return 0 }
            let sorted = values.sorted()
            let index = Int((pct / 100) * Double(sorted.count - 1))
            return sorted[min(index, sorted.count - 1)]
        }

        // Ruku — pitch (positions 2, 8)
        let rukuPitches = (steady(for: "rukuFirst") + steady(for: "rukuSecond")).map { $0.pitch }
        guard !rukuPitches.isEmpty else { return nil }

        // Upright — pitch (all qiyam + julus positions)
        let uprightIDs = ["qiyamStart", "qiyamAfterRukuFirst", "qiyamRakat2",
                          "qiyamAfterRukuSecond", "julusFirst", "julusSecond", "julusTashahhud"]
        let uprightPitches = uprightIDs.flatMap { steady(for: $0) }.map { $0.pitch }
        guard !uprightPitches.isEmpty else { return nil }

        // Sujood — angular distance of roll from 180° (positions 4, 6, 10, 12)
        let sujoodIDs = ["sujoodFirst", "sujoodSecond", "sujoodThird", "sujoodFourth"]
        let sujoodDeviations = sujoodIDs.flatMap { steady(for: $0) }.map { angDist($0.roll, 180) }
        guard !sujoodDeviations.isEmpty else { return nil }

        // Tasleem — yaw offset from qiyam baseline (position 9 baseline, 14+15 turns)
        let baselineYaws = steady(for: "qiyamAfterRukuSecond").map { $0.yaw }
        guard !baselineYaws.isEmpty else { return nil }
        let yawBaseline = baselineYaws.reduce(0, +) / Double(baselineYaws.count)

        let rightOffsets = steady(for: "tasleemRight").map { yawBaseline - $0.yaw }.filter { $0 > 0 }
        let leftOffsets  = steady(for: "tasleemLeft").map  { $0.yaw - yawBaseline }.filter { $0 > 0 }
        let allOffsets   = rightOffsets + leftOffsets
        guard !allOffsets.isEmpty else { return nil }

        let rukuP5  = percentile(rukuPitches, 5)
        let rukuP95 = percentile(rukuPitches, 95)
        let upP5    = percentile(uprightPitches, 5)
        let upP95   = percentile(uprightPitches, 95)

        if upP5 < rukuP95 {
            print(String(format: "[CalibrationAnalyzer] ⚠️ Gap warning: upright p5 (%.1f°) overlaps ruku p95 (%.1f°)", upP5, rukuP95))
        }

        return UserCalibrationProfile(
            rukuPitchLow:     rukuP5,
            rukuPitchHigh:    rukuP95,
            uprightPitchLow:  upP5,
            uprightPitchHigh: upP95,
            sujoodRollRadius: percentile(sujoodDeviations, 95),
            tasleemYawOffset: max(percentile(allOffsets, 5), 15)
        )
    }

    private func angDist(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }
}
