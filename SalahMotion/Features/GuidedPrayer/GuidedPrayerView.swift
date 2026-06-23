import SwiftUI

struct GuidedPrayerView: View {
    // Explicit @State so SwiftUI re-renders all screens when prayer changes.
    // Set in onBegin so the running screen always matches the selected prayer.
    @State private var prayerTime: PrayerTime = UserPreferences.shared.salatType.prayerTime

    @State private var session = PrayerStateMachine(sequence: GuidedSequenceGenerator.generate())
    @State private var isSilenced = false
    @State private var shareURL: URL?
    @State private var sessionFiles: [URL] = []

    var body: some View {
        Group {
            switch session.status {
            case .idle:      setupView
            case .running:   runningView
            case .complete:  completeView
            case .cancelled: cancelledView
            }
        }
        .animation(.default, value: session.status)
        .sheet(item: $shareURL) { ShareSheet(url: $0) }
        .onAppear { loadSessionFiles() }
        .onChange(of: session.status) {
            if session.status == .complete { loadSessionFiles() }
        }
    }

    // MARK: - Setup (idle)

    private var setupView: some View {
        PrayerSetupView(isAvailable: session.isAvailable) { salat, unitIds, lang, guidance, pace, muezzinId in
            prayerTime = salat.prayerTime   // ← explicit @State update drives all screens
            UserPreferences.shared.salatType       = salat
            UserPreferences.shared.selectedUnitIds = unitIds
            UserPreferences.shared.language        = lang
            UserPreferences.shared.guidanceLevel   = guidance
            UserPreferences.shared.pace            = pace
            UserPreferences.shared.muezzinId       = muezzinId
            session = PrayerStateMachine(
                sequence: GuidedSequenceGenerator.generate(salat: salat, language: lang),
                guidanceLevel: guidance
            )
            session.start()
        }
    }

    // MARK: - Running

    private var runningView: some View {
        let state = session.currentState
        let trackerPositions = session.visitedStates.enumerated().map { i, s in
            TrackerPosition(id: i, transliteration: s.displayLabel, arabic: s.arabic)
        }

        return ZStack {
            prayerTime.backgroundGradient
            .ignoresSafeArea()

            VStack(spacing: 0) {
                GuidedPrayerHeaderView(
                    isSilenced: $isSilenced,
                    currentRakat: session.currentRakat,
                    totalRakat: session.totalRakat,
                    prayerTime: prayerTime
                )

                Spacer()

                ZStack(alignment: .leading) {
                    PositionOrbView(arabicText: state.arabic, prayerTime: prayerTime)
                        .frame(maxWidth: .infinity)
                        .offset(x: 58)
                    PositionTrackerView(
                        positions: trackerPositions,
                        prayerTime: prayerTime,
                        progress: session.guidanceLevel.showsTimer ? session.confirmProgress : 0,
                        isSpeaking: session.isSpeaking
                    )
                    .padding(.leading, 24)
                    .offset(y: -65)
                }

                Spacer()

                GuidedPrayerBottomTextView(
                    positionName: state.displayLabel,
                    positionMeaning: state.englishMeaning,
                    recitationText: state.prayers.first?.utterance ?? "",
                    instruction: state.motionTrigger != nil ? "awaiting motion" : "timed",
                    prayerTime: prayerTime,
                    onEndPrayer: { session.cancel() }
                )
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Complete

    private var completeView: some View {
        ZStack {
            prayerTime.backgroundGradient
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72)).foregroundStyle(prayerTime.theme.orbGlow)
                Text("Prayer Complete").font(.title.weight(.semibold)).foregroundStyle(prayerTime.theme.ink)
                Text("Session saved to History.").foregroundStyle(prayerTime.theme.ink.opacity(0.55))
                Spacer()
                Button("Done") {
                    session = PrayerStateMachine(sequence: GuidedSequenceGenerator.generate(language: UserPreferences.shared.language))
                }
                .buttonStyle(.borderedProminent)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)

                if !sessionFiles.isEmpty {
                    Divider().overlay(.white.opacity(0.2)).padding(.top, 8)
                    historySection
                }
            }
            .padding()
        }
    }

    // MARK: - Cancelled

    private var cancelledView: some View {
        ZStack {
            prayerTime.backgroundGradient
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "xmark.circle")
                    .font(.system(size: 60)).foregroundStyle(prayerTime.theme.ink.opacity(0.5))
                Text("Prayer cancelled").foregroundStyle(prayerTime.theme.ink.opacity(0.55))
                Spacer()
                Button("Try Again") {
                    session = PrayerStateMachine(sequence: GuidedSequenceGenerator.generate(language: UserPreferences.shared.language))
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
            }
            .padding()
        }
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            List {
                ForEach(sessionFiles, id: \.self) { url in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sessionDate(from: url)).font(.subheadline)
                            Text(url.lastPathComponent).font(.caption2).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Button("Export") { shareURL = url }
                            .buttonStyle(.bordered).font(.caption)
                    }
                }
                .onDelete(perform: deleteSession)
            }
            .listStyle(.plain)
            .frame(height: min(CGFloat(sessionFiles.count) * 64, 200))
        }
    }

    // MARK: - Helpers

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
}

#Preview { GuidedPrayerView() }
