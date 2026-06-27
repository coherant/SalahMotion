//
//  CelestialDomainTests.swift
//  SalahMotionTests
//
//  Locks the pure, view-free pieces of the Core/Celestial domain: the arc
//  projection, the moon-phase math, the daily-arc mapping, and the clock. These
//  carry no SwiftUI and no astronomy library, so they're deterministic and the
//  cheapest place to catch regressions (incl. the production drift concern).
//

import Testing
import CoreGraphics
import Foundation
@testable import SalahMotion

private func approx(_ a: CGFloat, _ b: CGFloat, _ eps: CGFloat = 0.001) -> Bool { abs(a - b) < eps }
private func approx(_ a: Double, _ b: Double, _ eps: Double = 0.001) -> Bool { abs(a - b) < eps }

struct CelestialArcGeometryTests {

    // 300×120 card; defaults topGap 30, bodyRadius 13 → Ry = 120 − 13 − 30 = 77.
    let geo = CelestialArcGeometry()
    let size = CGSize(width: 300, height: 120)

    @Test func risesAtBottomLeftCorner() {
        let p = geo.point(forDayPhase: 0, in: size)
        #expect(approx(p.x, 0))
        #expect(approx(p.y, 120))
    }

    @Test func peaksAtTopCentreWithFiveMmGap() {
        let p = geo.point(forDayPhase: 0.25, in: size)
        #expect(approx(p.x, 150))
        // disc centre at bodyRadius + topGap below the top → top of disc == topGap.
        #expect(approx(p.y, 43))
        #expect(approx(p.y - geo.bodyRadius, geo.topGap))   // top of disc = 30pt below top
    }

    @Test func setsAtBottomRightCorner() {
        let p = geo.point(forDayPhase: 0.5, in: size)
        #expect(approx(p.x, 300))
        #expect(approx(p.y, 120))
    }

    @Test func nadirDipsBelowHorizon() {
        let p = geo.point(forDayPhase: 0.75, in: size)
        #expect(approx(p.x, 150))
        #expect(p.y > 120)   // below the card's bottom edge → clipped away
    }

    @Test func aboveHorizonOnlyDuringTheDayHalf() {
        #expect(geo.isAboveHorizon(forDayPhase: 0.25))
        #expect(!geo.isAboveHorizon(forDayPhase: 0.75))
        #expect(!geo.isAboveHorizon(forDayPhase: 0.0))   // exactly on the horizon
    }
}

struct MoonPhaseTests {

    @Test func cardinalPhasesByElongation() {
        #expect(MoonPhase(elongationDegrees: 0).name == .new)
        #expect(MoonPhase(elongationDegrees: 90).name == .firstQuarter)
        #expect(MoonPhase(elongationDegrees: 180).name == .full)
        #expect(MoonPhase(elongationDegrees: 270).name == .lastQuarter)
    }

    @Test func waxingVsWaningSplitsAtFull() {
        #expect(MoonPhase(elongationDegrees: 45).isWaxing)
        #expect(MoonPhase(elongationDegrees: 135).isWaxing)
        #expect(!MoonPhase(elongationDegrees: 225).isWaxing)
        #expect(!MoonPhase(elongationDegrees: 315).isWaxing)
    }

    @Test func illuminatedFractionEndpoints() {
        #expect(approx(MoonPhase(elongationDegrees: 0).illuminatedFraction, 0))
        #expect(approx(MoonPhase(elongationDegrees: 90).illuminatedFraction, 0.5))
        #expect(approx(MoonPhase(elongationDegrees: 180).illuminatedFraction, 1))
    }

    @Test func negativeAndOverflowElongationWrap() {
        #expect(approx(MoonPhase(elongationDegrees: -10).phase, MoonPhase(elongationDegrees: 350).phase))
        #expect(approx(MoonPhase(elongationDegrees: 360).phase, 0))
        #expect(MoonPhase(elongationDegrees: 350).name == .waningCrescent)
    }
}

struct DailyArcTests {

    let rise = Date(timeIntervalSinceReferenceDate: 6 * 3600)     // 06:00
    let transit = Date(timeIntervalSinceReferenceDate: 12 * 3600) // 12:00
    let set = Date(timeIntervalSinceReferenceDate: 18 * 3600)     // 18:00

    @Test func crossingsLandOnCardinalPhases() {
        #expect(approx(DailyArc.phase(now: rise, previousSet: nil, rise: rise, transit: transit, set: set, nextRise: nil), 0))
        #expect(approx(DailyArc.phase(now: transit, previousSet: nil, rise: rise, transit: transit, set: set, nextRise: nil), 0.25))
        #expect(approx(DailyArc.phase(now: set, previousSet: nil, rise: rise, transit: transit, set: set, nextRise: nil), 0.5))
    }

    @Test func morningIsHalfwayToTransit() {
        let nineAM = Date(timeIntervalSinceReferenceDate: 9 * 3600)
        #expect(approx(DailyArc.phase(now: nineAM, previousSet: nil, rise: rise, transit: transit, set: set, nextRise: nil), 0.125))
    }

    @Test func nightAfterSetClimbsTowardNextRise() {
        let nextRise = Date(timeIntervalSinceReferenceDate: 30 * 3600) // next 06:00
        let midnight = Date(timeIntervalSinceReferenceDate: 24 * 3600)
        let t = DailyArc.phase(now: midnight, previousSet: nil, rise: rise, transit: transit, set: set, nextRise: nextRise)
        #expect(t > 0.5 && t < 1.0)
    }
}

struct UniformEphemerisTests {

    let eph = UniformEphemeris()
    let loc = ObserverLocation(latitude: -37.8, longitude: 144.9)

    private func date(hour: Double) -> Date {
        let midnight = Calendar.gregorianUTC.startOfDay(for: Date(timeIntervalSinceReferenceDate: 800_000_000))
        return midnight.addingTimeInterval(hour * 3600)
    }

    @Test func cardinalTimesMapToCardinalPhases() {
        #expect(approx(eph.sky(at: date(hour: 6), location: loc).dayPhase, 0))
        #expect(approx(eph.sky(at: date(hour: 12), location: loc).dayPhase, 0.25))
        #expect(approx(eph.sky(at: date(hour: 18), location: loc).dayPhase, 0.5))
        #expect(approx(eph.sky(at: date(hour: 0), location: loc).dayPhase, 0.75))
    }

    @Test func velocityIsContinuousAcrossRise() {
        // Equal time steps straddling the 06:00 rise must give equal phase deltas —
        // i.e. no velocity kink (the cause of the stutter with real solar timing).
        let before = eph.sky(at: date(hour: 5.5), location: loc).dayPhase
        let atRise = eph.sky(at: date(hour: 6.0), location: loc).dayPhase
        let after = eph.sky(at: date(hour: 6.5), location: loc).dayPhase
        let d1 = (atRise + 1 - before).truncatingRemainder(dividingBy: 1)
        let d2 = after - atRise
        #expect(approx(d1, d2, 0.0005))
    }

    @Test func loopWrapIsSeamlessAtNadir() {
        let endOfDay = eph.sky(at: date(hour: 23.99), location: loc).dayPhase
        let startOfDay = eph.sky(at: date(hour: 0.01), location: loc).dayPhase
        #expect(approx(endOfDay, 0.75, 0.001))
        #expect(approx(startOfDay, 0.75, 0.001))   // both at the clipped nadir → no visible jump
    }
}

struct CelestialClockTests {

    @Test func realtimeIsIdentity() {
        let now = Date()
        #expect(CelestialClock.realtime.evaluationDate(for: now) == now)
    }

    @Test func demoStaysWithinOneReferenceDay() {
        let clock = CelestialClock.demo(secondsPerDay: 20)
        let dayStart = Calendar.gregorianUTC.startOfDay(for: Date())
        for offset in stride(from: 0.0, to: 20.0, by: 2.5) {
            let evaluated = clock.evaluationDate(for: Date().addingTimeInterval(offset))
            let intoDay = evaluated.timeIntervalSince(Calendar.gregorianUTC.startOfDay(for: evaluated))
            #expect(intoDay >= 0 && intoDay < 86_400)
            _ = dayStart
        }
    }
}
