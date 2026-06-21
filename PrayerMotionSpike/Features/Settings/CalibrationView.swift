import SwiftUI

struct CalibrationView: View {
    @State private var session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate())
    @State private var sessionFiles: [URL] = []
    @State private var shareURL: URL?
    @State private var activeProfile: UserCalibrationProfile? = UserCalibrationProfile.load()
    @State private var calibrationProfile: UserCalibrationProfile?

    var body: some View {
        NavigationStack {
            Group {
                switch session.status {
                case .idle:      idleView
                case .running:   runningView
                case .complete:  completeView
                case .cancelled: cancelledView
                }
            }
            .padding()
            .animation(.default, value: session.status)
            .navigationTitle("Calibration")
            .sheet(item: $shareURL) { ShareSheet(url: $0) }
            .onAppear { loadSessionFiles() }
            .onChange(of: session.status) {
                if session.status == .complete {
                    loadSessionFiles()
                    let result = CalibrationAnalyzer(samples: session.sessionSamples).analyze()
                    calibrationProfile = result
                    if let result {
                        activeProfile = result
                        result.save()
                    }
                }
            }
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 20) {
            Spacer()
            if !session.isAvailable {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60)).foregroundStyle(.orange)
                Text("Headphone motion unavailable").font(.title3.weight(.semibold))
                Text("Run on a physical device with AirPods connected.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            } else {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 72)).foregroundStyle(.teal)
                Text("Personal Calibration").font(.title.weight(.semibold))
                Text("\(session.states.count) phases · motion detection")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Begin Calibration") { session.start() }
                .buttonStyle(.borderedProminent)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .disabled(!session.isAvailable)

            if activeProfile != nil {
                VStack(spacing: 6) {
                    Label("Personal calibration active", systemImage: "checkmark.seal.fill")
                        .font(.caption).foregroundStyle(.teal)
                    Button("Reset to Global Calibration", role: .destructive) {
                        UserCalibrationProfile.reset()
                        activeProfile = nil
                    }
                    .font(.caption)
                }
                .padding(.top, 4)
            }

            if !sessionFiles.isEmpty {
                Divider().padding(.top, 8)
                historySection
            }
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            List {
                ForEach(sessionFiles, id: \.self) { url in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sessionDate(from: url))
                                .font(.subheadline)
                            Text(url.lastPathComponent)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Button("Export") { shareURL = url }
                            .buttonStyle(.bordered)
                            .font(.caption)
                    }
                }
                .onDelete(perform: deleteSession)
            }
            .listStyle(.plain)
            .frame(height: min(CGFloat(sessionFiles.count) * 64, 200))
        }
    }

    // MARK: - Running

    private var runningView: some View {
        let state = session.currentState
        return VStack(spacing: 20) {
            Text("Phase \(session.currentStateIndex + 1) of \(session.states.count)")
                .font(.subheadline).foregroundStyle(.secondary)

            Text(state.displayLabel)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity)

            modeBadge(for: state)

            if session.confirmProgress > 0 {
                VStack(spacing: 6) {
                    ProgressView(value: session.confirmProgress).tint(.teal)
                    Text("Holding…").font(.caption).foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 32) {
                angleCell("Pitch", session.pitch)
                angleCell("Roll",  session.roll)
                angleCell("Yaw",   session.yaw)
            }
            .font(.system(.title2, design: .monospaced))

            Spacer()

            Button("Cancel", role: .destructive) { session.cancel() }
                .buttonStyle(.bordered).frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func modeBadge(for state: PrayerState) -> some View {
        switch state.mode {
        case .auto:
            Label("Auto", systemImage: "play.circle.fill")
                .foregroundStyle(.blue)
        case .timed:
            Label("Timed", systemImage: "timer")
                .foregroundStyle(.green)
        case .motion:
            if let t = state.motionTrigger {
                Label("Awaiting: \(t.description)", systemImage: "sensor.tag.radiowaves.forward")
                    .foregroundStyle(.orange)
            }
        case .timedMotion:
            if let t = state.motionTrigger {
                Label("\(t.description) · timed", systemImage: "sensor.tag.radiowaves.forward")
                    .foregroundStyle(.purple)
            }
        }
    }

    // MARK: - Complete

    private var completeView: some View {
        VStack(spacing: 20) {
            Spacer()
            if calibrationProfile != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72)).foregroundStyle(.teal)
                Text("Calibration Complete").font(.title.weight(.semibold))
            } else {
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 72)).foregroundStyle(.orange)
                Text("Could Not Calibrate").font(.title.weight(.semibold))
                Text("Not enough data was captured. Please try again.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            }

            if let p = calibrationProfile {
                VStack(spacing: 0) {
                    resultRow("Ruku (pitch)",    String(format: "%.0f° to %.0f°",   p.rukuPitchLow, p.rukuPitchHigh))
                    resultRow("Upright (pitch)", String(format: "%.0f° to %.0f°",   p.uprightPitchLow, p.uprightPitchHigh))
                    resultRow("Sujood (roll)",   String(format: "≤ %.0f° from 180°", p.sujoodRollRadius))
                    resultRow("Tasleem (yaw)",   String(format: "≥ %.0f° offset",    p.tasleemYawOffset))
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                Text("Applied to motion detection.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()
            Button("Done") {
                calibrationProfile = nil
                session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate())
            }
            .buttonStyle(.borderedProminent)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Cancelled

    private var cancelledView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "xmark.circle")
                .font(.system(size: 60)).foregroundStyle(.secondary)
            Text("Calibration cancelled").foregroundStyle(.secondary)
            Spacer()
            Button("Try Again") {
                session = PrayerStateMachine(sequence: CalibrationSequenceGenerator.generate())
            }
            .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private func resultRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.vertical, 6)
    }

    private func loadSessionFiles() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let all = (try? FileManager.default.contentsOfDirectory(
            at: docs,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )) ?? []
        sessionFiles = all
            .filter { $0.lastPathComponent.hasPrefix("prayer_session_") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    private func deleteSession(at offsets: IndexSet) {
        for index in offsets { try? FileManager.default.removeItem(at: sessionFiles[index]) }
        sessionFiles.remove(atOffsets: offsets)
    }

    private func sessionDate(from url: URL) -> String {
        let stem = url.deletingPathExtension().lastPathComponent
        if let ts = Double(stem.replacingOccurrences(of: "prayer_session_", with: "")) {
            return DateFormatter.localizedString(
                from: Date(timeIntervalSince1970: ts),
                dateStyle: .medium, timeStyle: .short
            )
        }
        return stem
    }

    private func angleCell(_ name: String, _ value: Double) -> some View {
        VStack(spacing: 2) {
            Text(name).font(.caption).foregroundStyle(.secondary)
            Text(String(format: "%+.1f°", value)).fontWeight(.semibold)
        }
    }
}
