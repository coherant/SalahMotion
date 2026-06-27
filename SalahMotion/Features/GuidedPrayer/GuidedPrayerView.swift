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
            case .idle:                setupView
            case .running, .cancelled: runningView
            case .complete:            completeView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.status)
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
                sequence: GuidedSequenceGenerator.generate(salat: salat, language: lang, unitIds: unitIds),
                guidanceLevel: guidance
            )
            session.start()
        }
    }

    // MARK: - Running

    private var runningView: some View {
        let state = session.currentState
        // The orb and the position label hold the worshipper's posture. During a Muezzin
        // (container) row they keep the most recent posture rather than letting the call
        // recitation/name take over — the Muezzin's Arabic lives on the rail only.
        let heldPosture = state.isContainer
            ? session.visitedStates.last { !$0.isContainer }
            : state
        let orbArabic = heldPosture?.arabic ?? ""
        // The rail shows postures plus the Muezzin's own line. Posture rows keep their
        // position name (Ruku/Sujood/…); container (Muezzin) rows are flagged isMuezzin so
        // the tracker renders them distinctly — the spoken Arabic in the Muezzin hue.
        let trackerPositions = session.visitedStates
            .enumerated().map { i, s in
                TrackerPosition(
                    id: i,
                    transliteration: s.displayLabel,
                    arabic: s.arabic,
                    isMuezzin: s.isContainer
                )
            }

        return ZStack {
            prayerTime.backgroundGradient
            .ignoresSafeArea()

            VStack(spacing: 0) {
                GuidedPrayerHeaderView(
                    isSilenced: $isSilenced,
                    currentRakat: session.currentRakat,
                    totalRakat: session.totalRakat,
                    prayerTime: prayerTime,
                    unitLabel: session.currentUnitLabel,
                    unitIndex: session.currentUnitIndex,
                    unitCount: session.unitCount
                )

                Spacer()

                ZStack(alignment: .leading) {
                    PositionOrbView(arabicText: orbArabic, prayerTime: prayerTime)
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
                    positionName: heldPosture?.displayLabel ?? "",
                    positionMeaning: heldPosture?.englishMeaning ?? "",
                    recitationText: state.prayers.first?.utterance ?? "",
                    instruction: state.motionTrigger != nil ? "awaiting motion" : "timed",
                    prayerTime: prayerTime,
                    onCancel: { session.cancel() },
                    onNavigate: {
                        session = PrayerStateMachine(
                            sequence: GuidedSequenceGenerator.generate(language: UserPreferences.shared.language)
                        )
                    }
                )
                .padding(.bottom, 40)
            }

            // Tasbīḥ counter — shown during a container `.count` dhikr row (display only;
            // tap scaffolding is in the state machine, not yet bound). CONGREGATIONAL-CONTAINER.md §4.
            if let remaining = session.tasbihRemaining {
                VStack {
                    TasbihCounterView(
                        remaining: remaining,
                        total: state.callID.map { CallLibrary.count($0) } ?? remaining,
                        prayerTime: prayerTime
                    )
                    .padding(.top, 116)
                    Spacer()
                }
                .transition(.opacity)
            }

            // Silent Mode escape hatch — fades in after a long hold with no detected
            // movement, so a missed sensor read never strands the worshipper.
            // See docs/guided/CONGREGATIONAL-CONTAINER.md §3.
            if session.escapeHatchVisible {
                VStack {
                    Spacer()
                    Button { session.requestManualAdvance() } label: {
                        Label("Tap to continue", systemImage: "hand.tap")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(prayerTime.theme.ink.opacity(0.75))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.bottom, 124)
                }
                .transition(.opacity)
            }

            if let t = session.unitTransition {
                UnitTransitionCardView(from: t.from, to: t.to, prayerTime: prayerTime)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: session.unitTransition)
        .animation(.easeInOut(duration: 0.4), value: session.escapeHatchVisible)
        .animation(.easeInOut(duration: 0.3), value: session.tasbihRemaining)
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
