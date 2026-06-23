import SwiftUI
import Combine

// MARK: - Calibration step (8 posture types across the 15-state sequence)

private enum CalibrationStep: Int, CaseIterable {
    case qiyam, ruku, itidal, sujood, julus, tashahhud, tasleemRight, tasleemLeft

    var label: String {
        switch self {
        case .qiyam:        return "Qiyam"
        case .ruku:         return "Rukūʿ"
        case .itidal:       return "Iʿtidāl"
        case .sujood:       return "Sujūd"
        case .julus:        return "Julūs"
        case .tashahhud:    return "Tashahhud"
        case .tasleemRight: return "Right"
        case .tasleemLeft:  return "Left"
        }
    }

    var arabic: String {
        switch self {
        case .qiyam:        return "قِيَام"
        case .ruku:         return "رُكُوع"
        case .itidal:       return "اعتدال"
        case .sujood:       return "سُجُود"
        case .julus:        return "جُلُوس"
        case .tashahhud:    return "تَشَهُّد"
        case .tasleemRight: return "تسليم"
        case .tasleemLeft:  return "تسليم"
        }
    }

    var chip: String {
        switch self {
        case .qiyam:        return "Standing · arms at sides"
        case .ruku:         return "Bowing · hands to the knees"
        case .itidal:       return "Standing · after bowing"
        case .sujood:       return "Prostration · forehead to the ground"
        case .julus:        return "Sitting · upright on knees"
        case .tashahhud:    return "Sitting · finger raised"
        case .tasleemRight: return "Salutation · head right"
        case .tasleemLeft:  return "Salutation · head left"
        }
    }

    var imageName: String? {
        switch self {
        case .qiyam:  return "calib-qiyam"
        case .ruku:   return "calib-ruku"
        case .sujood: return "calib-sujud"
        default:      return nil
        }
    }
}

private extension PrayerStateID {
    var calibrationStep: CalibrationStep {
        switch self {
        case .r1QiyamFull, .r2QiyamFull, .r3QiyamFatiha, .r4QiyamFatiha:
            return .qiyam
        case .r1Ruku, .r2Ruku, .r3Ruku, .r4Ruku:
            return .ruku
        case .r1QiyamAfterRuku, .r2QiyamAfterRuku, .r3QiyamAfterRuku, .r4QiyamAfterRuku:
            return .itidal
        case .r1SujoodFirst, .r1SujoodSecond, .r2SujoodFirst, .r2SujoodSecond,
             .r3SujoodFirst, .r3SujoodSecond, .r4SujoodFirst, .r4SujoodSecond:
            return .sujood
        case .r1JulusBetween, .r2JulusBetween, .r3JulusBetween, .r4JulusBetween:
            return .julus
        case .julusFull, .julusShort:
            return .tashahhud
        case .tasleemRight:
            return .tasleemRight
        case .tasleemLeft:
            return .tasleemLeft
        }
    }
}

// MARK: - Progress arc shape

private struct CaptureArc: Shape {
    var progress: Double
    var animatableData: Double { get { progress } set { progress = newValue } }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(center: .init(x: rect.midX, y: rect.midY),
                 radius: rect.width / 2,
                 startAngle: .degrees(-90),
                 endAngle: .degrees(-90 + 360 * max(0, min(1, progress))),
                 clockwise: false)
        return p
    }
}

// MARK: - Calibration view

struct CalibrationView: View {

    @State private var session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate(), guidanceLevel: .full, useDefaultThresholds: true)
    @State private var calibrationProfile: UserCalibrationProfile?
    @State private var activeProfile: UserCalibrationProfile? = UserCalibrationProfile.load()
    @State private var prayerTime: PrayerTime = .current
    private var accent: Color { prayerTime.theme.accent }

    private var currentStep: CalibrationStep { session.currentState.id.calibrationStep }

    private var completedSteps: Set<CalibrationStep> {
        var done = Set<CalibrationStep>()
        for i in 0..<session.currentStateIndex {
            done.insert(session.states[i].id.calibrationStep)
        }
        done.remove(currentStep)
        return done
    }

    var body: some View {
        ZStack {
            prayerTime.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 8)
                Spacer(minLength: 0)
                hatifBar
                    .padding(.horizontal, 22)
                Spacer(minLength: 0)
                captureDial
                postureLabel
                    .padding(.top, 16)
                    .padding(.horizontal, 22)
                Spacer(minLength: 0)
                stepperRow
                    .padding(.horizontal, 22)
                bottomArea
                    .padding(.top, 14)
                    .padding(.bottom, 32)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.status)
        .onAppear { prayerTime = .current }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            prayerTime = .current
        }
        .onChange(of: session.status) {
            if session.status == .complete {
                let result = CalibrationAnalyzer(samples: session.sessionSamples).analyze()
                calibrationProfile = result
                if let result { activeProfile = result; result.save() }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Calibration")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(2.5)
                    .textCase(.uppercase)
                    .foregroundStyle(accent)
                Text("Tune your movements")
                    .font(Typography.display(26, weight: .medium))
                    .foregroundStyle(DesignTokens.ink)
            }

            Spacer()

        }
        .padding(.horizontal, 22)
    }

    // MARK: - Hātif voice bar

    private var hatifBar: some View {
        let isActive = session.status == .running
        let barHeights: [CGFloat] = [5, 9, 6, 12, 7, 11, 5, 9, 6]
        return HStack(spacing: 12) {
            HStack(alignment: .center, spacing: 2.5) {
                ForEach(Array(barHeights.enumerated()), id: \.offset) { i, h in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(accent)
                        .frame(width: 2.5, height: h)
                        .scaleEffect(y: (isActive && session.isSpeaking) ? 1.0 : 0.25, anchor: .center)
                        .animation(
                            .easeInOut(duration: 1.2 + Double(i % 3) * 0.3)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.1),
                            value: session.isSpeaking
                        )
                }
            }
            .frame(height: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text("HĀTIF · GUIDING")
                    .font(Typography.eyebrow)
                    .tracking(1.5)
                    .foregroundStyle(accent)
                Text(isActive ? currentStep.chip : "Ready when you are")
                    .font(Typography.ui(13))
                    .foregroundStyle(DesignTokens.muted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(accent.opacity(0.2), lineWidth: 1))
        )
    }

    // MARK: - Capture dial

    private var captureDial: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1.5)
                .frame(width: 230, height: 230)

            CaptureArc(progress: session.status == .running ? session.confirmProgress : 0)
                .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 222, height: 222)
                .animation(.linear(duration: 0.1), value: session.confirmProgress)

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 140, height: 1)
                .offset(y: 82)

            // Complete overlay inside the dial
            if session.status == .complete {
                dialCompleteOverlay
            } else if session.status == .cancelled {
                postureContent(for: .qiyam)
            } else {
                postureContent(for: currentStep)
            }
        }
        .frame(width: 230, height: 230)
    }

    private var dialCompleteOverlay: some View {
        VStack(spacing: 6) {
            if calibrationProfile != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(accent)
                Text("Complete")
                    .font(Typography.display(16, weight: .medium))
                    .foregroundStyle(DesignTokens.ink)
            } else {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 52))
                    .foregroundStyle(DesignTokens.faint)
                Text("Try again")
                    .font(Typography.display(16, weight: .medium))
                    .foregroundStyle(DesignTokens.muted)
            }
        }
    }

    @ViewBuilder
    private func postureContent(for step: CalibrationStep) -> some View {
        if let name = step.imageName, let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: 118)
        } else {
            VStack(spacing: 4) {
                Text(step.arabic)
                    .font(Typography.arabic(32))
                    .foregroundStyle(accent)
                Text(step.label)
                    .font(Typography.display(15, weight: .medium))
                    .foregroundStyle(DesignTokens.muted)
            }
        }
    }

    // MARK: - Posture label

    private var postureLabel: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(currentStep.arabic)
                    .font(Typography.arabic(28))
                    .foregroundStyle(DesignTokens.ink)
                Text(currentStep.label)
                    .font(Typography.display(22, weight: .medium))
                    .foregroundStyle(DesignTokens.muted)
            }
        }
        .multilineTextAlignment(.center)
        .opacity(session.status == .running ? 1 : 0.4)
    }

    // MARK: - Motion sampling bars

    // MARK: - 8-step stepper

    private var stepperRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(CalibrationStep.allCases.enumerated()), id: \.element.rawValue) { index, step in
                if index > 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                }
                stepperDot(step: step,
                           completed: completedSteps.contains(step),
                           current: step == currentStep && session.status == .running)
            }
        }
    }

    private func stepperDot(step: CalibrationStep, completed: Bool, current: Bool) -> some View {
        ZStack {
            Circle()
                .fill(completed ? accent : (current ? Color.clear : Color.white.opacity(0.06)))
                .frame(width: 22, height: 22)

            if current {
                Circle()
                    .strokeBorder(accent, lineWidth: 2)
                    .frame(width: 22, height: 22)
            }

            if completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DesignTokens.darkOnAccent)
            } else if current {
                Circle().fill(accent).frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Bottom area (state-driven)

    @ViewBuilder
    private var bottomArea: some View {
        VStack(spacing: 12) {
            // Contextual content above the button
            if session.status == .complete, let p = calibrationProfile {
                calibrationResultCard(p)
                    .padding(.horizontal, 22)
            } else if session.status == .idle, activeProfile != nil {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                        Text("Personal calibration active")
                            .font(Typography.ui(11))
                    }
                    .foregroundStyle(accent)

                    Button("Reset to defaults", role: .destructive) {
                        UserCalibrationProfile.reset()
                        activeProfile = nil
                    }
                    .font(Typography.ui(11))
                    .foregroundStyle(DesignTokens.faint)
                }
            }

            // Single action button
            Button {
                switch session.status {
                case .idle:
                    session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate(), guidanceLevel: .full, useDefaultThresholds: true)
                    session.start()
                case .running:
                    session.cancel()
                case .complete, .cancelled:
                    calibrationProfile = nil
                    session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate(), guidanceLevel: .full, useDefaultThresholds: true)
                }
            } label: {
                Text(buttonLabel)
                    .font(Typography.eyebrow)
                    .tracking(1.5)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .strokeBorder(accent.opacity(0.5), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(session.status == .idle && !session.isAvailable)
            .opacity(session.status == .idle && !session.isAvailable ? 0.4 : 1)

            if session.status == .idle && !session.isAvailable {
                Text("Connect AirPods to begin")
                    .font(Typography.ui(11))
                    .foregroundStyle(accent.opacity(0.7))
            }
        }
    }

    private var buttonLabel: String {
        switch session.status {
        case .idle:      return "BEGIN CALIBRATION"
        case .running:   return "END CALIBRATION"
        case .complete:  return calibrationProfile != nil ? "BEGIN AGAIN" : "TRY AGAIN"
        case .cancelled: return "TRY AGAIN"
        }
    }

    // MARK: - Result card

    private func calibrationResultCard(_ p: UserCalibrationProfile) -> some View {
        VStack(spacing: 0) {
            resultRow("Ruku",    String(format: "%.0f° to %.0f°",    p.rukuPitchLow,     p.rukuPitchHigh))
            resultRow("Upright", String(format: "%.0f° to %.0f°",    p.uprightPitchLow,  p.uprightPitchHigh))
            resultRow("Sujood",  String(format: "≤ %.0f° from 180°", p.sujoodRollRadius))
            resultRow("Tasleem", String(format: "≥ %.0f° offset",    p.tasleemYawOffset))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DesignTokens.cardBorder, lineWidth: 1))
        )
    }

    private func resultRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.ui(13))
                .foregroundStyle(DesignTokens.muted)
            Spacer()
            Text(value)
                .font(Typography.ui(13, weight: .semibold))
                .foregroundStyle(DesignTokens.ink)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
        }
    }
}

// MARK: - Previews

#Preview("Idle")      { CalibrationView() }
#Preview("Cancelled") { CalibrationView() }
