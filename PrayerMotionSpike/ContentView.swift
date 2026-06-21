import SwiftUI
import CoreMotion
import AVFoundation

// MARK: - Root

struct ContentView: View {
    var body: some View {
        TabView {
            ReactivePrayerView()
                .tabItem { Label("Guided", systemImage: "moon.stars.fill") }
            GuidedRecordingView()
                .tabItem { Label("Calibration", systemImage: "figure.stand") }
            ManualRecordingView()
                .tabItem { Label("Manual", systemImage: "hand.tap") }
        }
    }
}

// MARK: - Calibration (Guided Recording)

struct GuidedRecordingView: View {
    @State private var participantName: String = ""
    @State private var session = PrayerStateMachine(sequence: GuidedSequenceGenerator.generate())
    @State private var sessionFiles: [URL] = []
    @State private var shareURL: URL?

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
                if session.status == .complete { loadSessionFiles() }
            }
        }
    }

    // MARK: Idle

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
                Image(systemName: "figure.stand")
                    .font(.system(size: 72)).foregroundStyle(.blue)
                Text("Calibration Recording").font(.title.weight(.semibold))
                Text("\(session.states.count) phases · records sensor data per position")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            Spacer()
            TextField("Participant name", text: $participantName)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            Button("Begin Calibration") {
                let name = participantName.trimmingCharacters(in: .whitespaces)
                session = PrayerStateMachine(sequence: GuidedSequenceGenerator.generate(), participantName: name)
                session.start()
            }
            .buttonStyle(.borderedProminent)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity)
            .disabled(!session.isAvailable || participantName.trimmingCharacters(in: .whitespaces).isEmpty)

            if !sessionFiles.isEmpty {
                Divider().padding(.top, 8)
                historySection
            }
        }
    }

    // MARK: History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            List {
                ForEach(sessionFiles, id: \.self) { url in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(participantFromURL(url))
                                .font(.subheadline).fontWeight(.semibold)
                            Text(sessionDate(from: url))
                                .font(.caption).foregroundStyle(.secondary)
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

    // MARK: Running

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
                    ProgressView(value: session.confirmProgress).tint(.green)
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

    // MARK: Complete

    private var completeView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72)).foregroundStyle(.green)
            Text("Calibration Complete").font(.title.weight(.semibold))
            Text("Session saved to History.").foregroundStyle(.secondary)
            Spacer()
            Button("Done") {
                session = PrayerStateMachine(sequence: GuidedSequenceGenerator.generate())
            }
            .buttonStyle(.borderedProminent)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Cancelled

    private var cancelledView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "xmark.circle")
                .font(.system(size: 60)).foregroundStyle(.secondary)
            Text("Session cancelled").foregroundStyle(.secondary)
            Spacer()
            Button("Try Again") {
                session = PrayerStateMachine(sequence: GuidedSequenceGenerator.generate())
            }
            .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
        }
    }

    // MARK: Helpers

    private func loadSessionFiles() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let all = (try? FileManager.default.contentsOfDirectory(
            at: docs,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        )) ?? []
        sessionFiles = all
            .filter { $0.lastPathComponent.hasPrefix("prayer_calibration_") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    private func deleteSession(at offsets: IndexSet) {
        for index in offsets { try? FileManager.default.removeItem(at: sessionFiles[index]) }
        sessionFiles.remove(atOffsets: offsets)
    }

    private func sessionDate(from url: URL) -> String {
        let stem = url.deletingPathExtension().lastPathComponent
        // filename: prayer_calibration_<slug>_<timestamp>
        if let ts = Double(stem.components(separatedBy: "_").last ?? "") {
            return DateFormatter.localizedString(
                from: Date(timeIntervalSince1970: ts),
                dateStyle: .medium, timeStyle: .short
            )
        }
        return stem
    }

    private func participantFromURL(_ url: URL) -> String {
        let stem = url.deletingPathExtension().lastPathComponent
        let withoutPrefix = stem.replacingOccurrences(of: "prayer_calibration_", with: "")
        let parts = withoutPrefix.components(separatedBy: "_")
        guard parts.count >= 2 else { return withoutPrefix }
        return parts.dropLast().joined(separator: "_")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private func angleCell(_ name: String, _ value: Double) -> some View {
        VStack(spacing: 2) {
            Text(name).font(.caption).foregroundStyle(.secondary)
            Text(String(format: "%+.1f°", value)).fontWeight(.semibold)
        }
    }
}

// MARK: - Motion (shared by Manual tab)

struct MotionSample {
    let timestamp: Double
    let pitch: Double
    let roll: Double
    let yaw: Double
    let label: String
}

@Observable
final class MotionManager {
    private let headphoneManager = CMHeadphoneMotionManager()
    private let queue = OperationQueue()
    private var startDate: Date?

    var isAvailable: Bool { headphoneManager.isDeviceMotionAvailable }
    var isRecording = false
    var pitch: Double = 0
    var roll: Double = 0
    var yaw: Double = 0
    var currentLabel = "unlabeled"
    private(set) var samples: [MotionSample] = []

    func start() {
        guard headphoneManager.isDeviceMotionAvailable else { return }
        samples = []
        currentLabel = "unlabeled"
        startDate = Date()
        isRecording = true

        headphoneManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let elapsed = Date().timeIntervalSince(self.startDate ?? Date())
            let p = motion.attitude.pitch * 180 / .pi
            let r = motion.attitude.roll  * 180 / .pi
            let y = motion.attitude.yaw   * 180 / .pi
            DispatchQueue.main.async {
                self.pitch = p
                self.roll  = r
                self.yaw   = y
                self.samples.append(MotionSample(timestamp: elapsed, pitch: p, roll: r, yaw: y, label: self.currentLabel))
            }
        }
    }

    func stop() {
        headphoneManager.stopDeviceMotionUpdates()
        isRecording = false
    }

    func setLabel(_ label: String) { currentLabel = label }

    var csvString: String {
        var lines = ["timestamp_s,pitch_deg,roll_deg,yaw_deg,label"]
        for s in samples {
            lines.append(String(format: "%.4f,%.4f,%.4f,%.4f,%@",
                                s.timestamp, s.pitch, s.roll, s.yaw, s.label))
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Manual Recording

struct ManualRecordingView: View {
    @State private var motion = MotionManager()
    @State private var shareURL: URL?

    private let positions = ["Standing (Qiyam)", "Ruku", "Sujood", "Sitting (Julus)"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !motion.isAvailable {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundStyle(.orange)
                        Text("Headphone motion not available").font(.headline)
                        Text("Run on a physical device with AirPods connected.")
                            .foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    readout
                    Divider()
                    positionButtons
                    Spacer()
                    controlRow
                }
            }
            .padding()
            .navigationTitle("Manual Recording")
            .sheet(item: $shareURL) { ShareSheet(url: $0) }
        }
    }

    private var readout: some View {
        VStack(spacing: 6) {
            Text(motion.isRecording ? "Label: \(motion.currentLabel)" : "Not recording")
                .font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 32) {
                angleCell("Pitch", motion.pitch)
                angleCell("Roll",  motion.roll)
                angleCell("Yaw",   motion.yaw)
            }
            .font(.system(.title, design: .monospaced))
            Text("\(motion.samples.count) samples").font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    private func angleCell(_ name: String, _ value: Double) -> some View {
        VStack(spacing: 2) {
            Text(name).font(.caption).foregroundStyle(.secondary)
            Text(String(format: "%+.1f°", value)).fontWeight(.semibold)
        }
    }

    private var positionButtons: some View {
        VStack(spacing: 10) {
            Text("Tap to label current position").font(.subheadline).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(positions, id: \.self) { pos in
                    Button(pos) { motion.setLabel(pos) }
                        .buttonStyle(.bordered)
                        .tint(motion.currentLabel == pos ? .blue : .primary)
                        .disabled(!motion.isRecording)
                }
            }
        }
    }

    private var controlRow: some View {
        VStack(spacing: 14) {
            Button(motion.isRecording ? "Stop" : "Start") {
                motion.isRecording ? motion.stop() : motion.start()
            }
            .buttonStyle(.borderedProminent)
            .tint(motion.isRecording ? .red : .green)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity)

            Button("Export CSV") { prepareExport() }
                .disabled(motion.samples.isEmpty || motion.isRecording)
                .frame(maxWidth: .infinity)
        }
    }

    private func prepareExport() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("prayer_motion_\(Int(Date().timeIntervalSince1970)).csv")
        try? motion.csvString.write(to: url, atomically: true, encoding: .utf8)
        shareURL = url
    }
}

// MARK: - Shared

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_: UIActivityViewController, context: Context) {}
}

#Preview {
    ContentView()
}
