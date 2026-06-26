//
//  TasbihCounterView.swift
//  SalahMotion
//
//  A clean, non-interactive tasbīḥ counter shown during a container `.count` dhikr row
//  (C-4 ×3, C-6/C-7/C-8 ×33). It displays the repetitions remaining over a progress ring.
//
//  Stage 2d: DISPLAY ONLY. The tap scaffolding lives in the state machine
//  (`PrayerStateMachine.tapTasbih()` decrements `tasbihRemaining`) but is not yet bound to
//  a control — advancement is via the existing "Tap to continue" hatch. A later stage wires
//  the tap (orb / haptic) to `tapTasbih()` and auto-advances at zero.
//  See docs/guided/CONGREGATIONAL-CONTAINER.md §4.
//

import SwiftUI

struct TasbihCounterView: View {
    let remaining: Int
    let total: Int
    let prayerTime: PrayerTime

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(total - remaining) / Double(total)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(prayerTime.theme.ink.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(prayerTime.theme.orbGlow,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.25), value: progress)
            Text("\(remaining)")
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(prayerTime.theme.ink)
        }
        .frame(width: 64, height: 64)
        .background(.ultraThinMaterial, in: Circle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tasbīḥ counter")
        .accessibilityValue("\(remaining) of \(total) remaining")
    }
}
