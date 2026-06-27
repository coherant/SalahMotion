//
//  GuidedSnapshotTests.swift
//  SalahMotionTests
//
//  Golden snapshot of the emitted guided [PrayerState] sequences.
//  The spine of the observance-sequencer refactor (see docs/guided/REFACTOR-PLAN.md):
//  behavior-preserving stages must leave this byte-identical; behavior-changing
//  stages must show an intentional, reviewed diff.
//
//  Determinism: sequences are generated with language: .english and durations are
//  serialized SYMBOLICALLY (.pace / .fixed(x)) — so neither the user's language nor
//  pace preference can affect the snapshot.
//

import Testing
import Foundation
@testable import SalahMotion

struct GuidedSnapshotTests {

    // MARK: Serialization (stable, human-readable, captures every field that matters)

    private func dur(_ d: PrayerDuration) -> String {
        switch d {
        case .pace:          return "pace"
        case .fixed(let v):  return "fixed(\(num(v)))"
        }
    }
    private func num(_ d: Double) -> String { d == d.rounded() ? String(Int(d)) : String(d) }
    private func q(_ s: String?) -> String { s.map { "\"\($0)\"" } ?? "-" }

    private func serialize(_ name: String, _ states: [PrayerState]) -> String {
        var out = "=== \(name) (\(states.count) states) ===\n"
        for (i, s) in states.enumerated() {
            let trig = s.motionTrigger.map { "\($0)" } ?? "-"
            out += "[\(i)] \(s.id.rawValue) r\(s.rakatNumber) \(s.mode.rawValue)"
            out += " unit=\(s.unitIndex):\(q(s.unitLabel))"
            if let callID = s.callID { out += " call=\(callID.rawValue)" }  // container rows only
            out += " trigger=\(trig)"
            out += " reprompt=\(num(s.repromptInterval)) maxReprompts=\(s.maxReprompts.map(String.init) ?? "-")"
            out += " progressDuringWait=\(s.showProgressDuringWait)\n"
            out += "    label=\(q(s.displayLabel)) ar=\(q(s.arabic)) en=\(q(s.englishMeaning))\n"
            out += "    entry=\(q(s.entrySpeech)) reprompt=\(q(s.repromptAudio)) exit=\(q(s.exitSpeech))\n"
            let prayers = s.prayers.map { line -> String in
                let clip = line.clipID.map { " clip=\($0.rawValue)" } ?? ""
                return "\(q(line.utterance))@\(dur(line.duration))\(clip)"
            }.joined(separator: ", ")
            out += "    prayers=[\(prayers)]\n"
        }
        return out
    }

    private func fullSnapshot() -> String {
        var parts: [String] = []
        for salat in SalatType.allCases {
            // Full observance: every unit selected, so the snapshot is independent of the
            // user's selectedUnitIds (which would otherwise be read from UserDefaults).
            let allUnits = Set(salat.units.map(\.id))
            // container: true pins the Muezzin frame on regardless of the toggle default
            // (UserPreferences.muezzinEnabled, default off), so the golden file is deterministic.
            parts.append(serialize(salat.rawValue,
                                   GuidedSequenceGenerator.generate(salat: salat, language: .english,
                                                                    unitIds: allUnits, container: true)))
        }
        parts.append(serialize("witr", GuidedSequenceGenerator.witrSequence(language: .english)))
        return parts.joined(separator: "\n")
    }

    // MARK: Test

    @Test func guidedSequencesMatchSnapshot() throws {
        let actual = fullSnapshot()
        let dir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
        let ref = dir.appendingPathComponent("guided-sequences.txt")
        let fm = FileManager.default

        if !fm.fileExists(atPath: ref.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            try actual.write(to: ref, atomically: true, encoding: .utf8)
            Issue.record("Baseline snapshot written to \(ref.path) — re-run to verify.")
            return
        }

        let expected = try String(contentsOf: ref, encoding: .utf8)
        if actual != expected {
            let actualURL = dir.appendingPathComponent("guided-sequences.actual.txt")
            try? actual.write(to: actualURL, atomically: true, encoding: .utf8)
            Issue.record("Snapshot mismatch — wrote actual to \(actualURL.path); diff vs guided-sequences.txt.")
        }
        #expect(actual == expected)
    }
}
