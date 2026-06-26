//
//  CallLibraryTests.swift
//  SalahMotionTests
//
//  Guards the C- container namespace (the Muezzin's content) — Stage 2a.
//  Catches CallID ↔ calls.json drift at test time rather than via a runtime
//  assertionFailure, and asserts the verbatim-reuse + count invariants.
//

import Testing
import Foundation
@testable import SalahMotion

struct CallLibraryTests {

    private let allIDs: [CallID] = [
        .c1, .c1F, .c2, .c3, .c4, .c5, .c6, .c7, .c8, .c9, .c10, .c11,
    ]

    @Test func everyCallIDResolves() {
        for id in allIDs {
            #expect(!CallLibrary.arabic(id).isEmpty, "missing arabic for \(id.rawValue)")
            #expect(!CallLibrary.transliteration(id).isEmpty, "missing transliteration for \(id.rawValue)")
            #expect(!CallLibrary.meaning(id).isEmpty, "missing meaning for \(id.rawValue)")
            #expect(!CallLibrary.name(id).isEmpty, "missing name for \(id.rawValue)")
        }
    }

    @Test func shapesAreCorrect() {
        #expect(CallLibrary.shape(.c1)  == .call)
        #expect(CallLibrary.shape(.c2)  == .call)
        #expect(CallLibrary.shape(.c3)  == .boundary)
        #expect(CallLibrary.shape(.c6)  == .dhikr)
        #expect(CallLibrary.shape(.c11) == .closing)
    }

    @Test func countFormulaIsLocked() {
        // 33 / 33 / 33 + 1 tahlīl = 100 (Muslim) — see calls.md / CONGREGATIONAL-CONTAINER §B.
        #expect(CallLibrary.count(.c6) == 33)
        #expect(CallLibrary.count(.c7) == 33)
        #expect(CallLibrary.count(.c8) == 33)
        #expect(CallLibrary.count(.c9) == 1)
        #expect(CallLibrary.count(.c6) + CallLibrary.count(.c7)
              + CallLibrary.count(.c8) + CallLibrary.count(.c9) == 100)
        #expect(CallLibrary.count(.c4) == 3)   // istighfār ×3
    }

    @Test func verbatimReuseMatchesPrayerLibrary() {
        // One source, re-voiced — not duplicated. C-3 and C-10 reuse these P-ids' Arabic
        // byte-for-byte. (C-8 takbīr is the same phrase as P-0 but re-vowelled to match the
        // C-6/C-7 dhikr trio, so it is intentionally not byte-equal — see calls.md.)
        #expect(CallLibrary.arabic(.c3)  == PrayerLibrary.text(.p23, .arabic)) // boundary du'ā
        #expect(CallLibrary.arabic(.c10) == PrayerLibrary.text(.p9,  .arabic)) // ṣalawāt
    }
}
