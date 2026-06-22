import SwiftUI

struct ReactivePrayerView: View {
    var prayerTime: PrayerTime = .isha

    @State private var session = PrayerStateMachine(sequence: GuidedSequenceGenerator.generate(language: UserPreferences.shared.language))
    @State private var isSilenced = false
    @State private var shareURL: URL?
    @State private var sessionFiles: [URL] = []

    var body: some View {
        Group {
            switch session.status {
            case .idle:      idleView
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

    // MARK: - Idle

    private var idleView: some View {
        ZStack {
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                if !session.isAvailable {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60)).foregroundStyle(.orange)
                    Text("Headphone motion unavailable")
                        .font(.title3.weight(.semibold)).foregroundStyle(.white)
                    Text("Run on a physical device with AirPods connected.")
                        .foregroundStyle(.white.opacity(0.6)).multilineTextAlignment(.center)
                } else {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 72)).foregroundStyle(prayerTime.theme.orbGlow)
                    Text("2-Rakat Prayer")
                        .font(.title.weight(.semibold)).foregroundStyle(.white)
                    Text("\(session.states.count) phases · motion guided")
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()

                // Language + Pace pickers
                HStack(spacing: 12) {
                    // Language
                    Menu {
                        ForEach(Language.allCases) { lang in
                            Button {
                                UserPreferences.shared.language = lang
                                session = PrayerStateMachine(sequence: GuidedSequenceGenerator.generate(language: lang))
                            } label: {
                                if lang == UserPreferences.shared.language {
                                    Label(lang.displayName, systemImage: "checkmark")
                                } else {
                                    Text(lang.displayName)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                            Text(UserPreferences.shared.language.displayName)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                    }

                    // Pace
                    Menu {
                        ForEach(PrayerPace.allCases) { pace in
                            Button {
                                UserPreferences.shared.pace = pace
                            } label: {
                                if pace == UserPreferences.shared.pace {
                                    Label(pace.displayName, systemImage: "checkmark")
                                } else {
                                    Text(pace.displayName)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.medium")
                            Text(UserPreferences.shared.pace.displayName)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)

                Button("Begin Prayer") { session.start() }
                    .buttonStyle(.borderedProminent)
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .disabled(!session.isAvailable)
                    .padding(.horizontal, 24)

                if !sessionFiles.isEmpty {
                    Divider().overlay(.white.opacity(0.2)).padding(.top, 8)
                    historySection
                }
            }
            .padding()
        }
    }

    // MARK: - Running

    private var runningView: some View {
        let state = session.currentState
        let trackerPositions = session.visitedStates.enumerated().map { i, s in
            TrackerPosition(id: i, transliteration: s.displayLabel, arabic: s.arabic)
        }

        return ZStack {
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                PrayerSessionHeaderView(
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

                PrayerSessionBottomTextView(
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
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72)).foregroundStyle(prayerTime.theme.orbGlow)
                Text("Prayer Complete").font(.title.weight(.semibold)).foregroundStyle(.white)
                Text("Session saved to History.").foregroundStyle(.white.opacity(0.55))
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
            LinearGradient(
                colors: [prayerTime.theme.gradientTop, prayerTime.theme.gradientBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "xmark.circle")
                    .font(.system(size: 60)).foregroundStyle(.white.opacity(0.5))
                Text("Prayer cancelled").foregroundStyle(.white.opacity(0.55))
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

#Preview("Isha")    { ReactivePrayerView(prayerTime: .isha) }
#Preview("Maghrib") { ReactivePrayerView(prayerTime: .maghrib) }
#Preview("Fajr")    { ReactivePrayerView(prayerTime: .fajr) }
