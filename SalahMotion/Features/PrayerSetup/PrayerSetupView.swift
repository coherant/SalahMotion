import SwiftUI

struct PrayerSetupView: View {
    let isAvailable: Bool
    let onBegin: (SalatType, Set<String>, Language, GuidanceLevel, PrayerPace, String) -> Void

    // @Environment injection — the Apple-recommended pattern for @Observable
    // singletons. SwiftUI reliably tracks and re-renders on every property change.
    @Environment(UserPreferences.self) private var prefs

    private var salat:     SalatType    { prefs.salatType }
    private var unitIds:   Set<String>  { prefs.selectedUnitIds }
    private var language:  Language     { prefs.language }
    private var guidance:  GuidanceLevel{ prefs.guidanceLevel }
    private var pace:      PrayerPace   { prefs.pace }
    private var muezzinId: String       { prefs.muezzinId }

    @State private var voice      = "hatif"
    @State private var sheetOpen  = false
    @State private var wavePhase  = false

    private var theme:   PrayerTimeTheme { salat.prayerTime.theme }
    private var accent:  Color           { salat.prayerTime.setupAccent }
    private var muezzin: Muezzin         { Muezzins.all.first { $0.id == muezzinId } ?? Muezzins.all[0] }

    private var totalRakats: Int {
        salat.units.reduce(0) { sum, unit in
            (unit.isObligatory || unitIds.contains(unit.id)) ? sum + unit.rakats : sum
        }
    }

    private var rakahLine: String {
        let hasOptional = salat.units.filter { !$0.isObligatory && unitIds.contains($0.id) }.count > 0
        if hasOptional {
            let parts = salat.units.compactMap { unit -> String? in
                guard unit.isObligatory || unitIds.contains(unit.id) else { return nil }
                return "\(unit.rakats) \(unit.displayName.lowercased())"
            }
            return "\(totalRakats) rakʿahs · \(parts.joined(separator: " + "))"
        }
        return "\(salat.fardRakats) rakʿahs · farḍ"
    }

    var body: some View {
        ZStack {
            ZStack(alignment: .top) {
                DesignTokens.setupGround
                RadialGradient(
                    colors: [accent.opacity(0.20), .clear],
                    center: UnitPoint(x: 0.5, y: 0.0),
                    startRadius: 0,
                    endRadius: 300
                )
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        heroCard
                        languageSection
                        voiceSection
                        guidanceSection
                        paceSection
                        muezzinSection
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 20)
                    .padding(.bottom, 4)
                }
                startFooter
            }
            .blur(radius: sheetOpen ? 3 : 0)
            .animation(.easeOut(duration: 0.25), value: sheetOpen)

            if sheetOpen {
                Color(hex: "#08070f")
                    .opacity(0.62)
                    .ignoresSafeArea()
                    .onTapGesture { sheetOpen = false }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    PrayerSetSheet(isPresented: $sheetOpen)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color.white.opacity(0.09))
                                .frame(height: 1)
                        }
                        .clipShape(UnevenRoundedRectangle(
                            topLeadingRadius: 28,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 28
                        ))
                        .shadow(color: .black.opacity(0.55), radius: 27, y: -11)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: sheetOpen)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 1) {
                Text("New session")
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(2.5)
                    .textCase(.uppercase)
                    .foregroundStyle(accent)
                Text("Guided Prayer")
                    .font(Typography.display(26, weight: .medium))
                    .foregroundStyle(DesignTokens.ink)
            }

            Spacer()

            Text(salat.prayerTime.displayTime)
                .font(Typography.ui(12.5))
                .foregroundStyle(DesignTokens.faint)
                .fixedSize()
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 0)
    }

    // MARK: - Hero card

    private var heroCard: some View {
        Button { sheetOpen = true } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(salat.periodLabel.uppercased()) · UP NEXT")
                        .font(Typography.ui(10.5, weight: .semibold))
                        .tracking(2.5)
                        .foregroundStyle(accent)

                    HStack(alignment: .firstTextBaseline, spacing: 11) {
                        Text(salat.arabicName)
                            .font(Typography.arabic(38))
                            .environment(\.layoutDirection, .rightToLeft)
                            .foregroundStyle(DesignTokens.ink)
                        Text(salat.displayName)
                            .font(Typography.display(28, weight: .medium))
                            .foregroundStyle(DesignTokens.muted)
                    }
                    .padding(.top, 10)

                    Text(rakahLine)
                        .font(Typography.ui(12.5))
                        .foregroundStyle(DesignTokens.muted)
                        .padding(.top, 8)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Change")
                        .font(Typography.ui(11, weight: .semibold))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(DesignTokens.muted)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.04))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
                )
                .padding(.top, 18)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.16), accent.opacity(0.03)],
                            startPoint: .init(x: 0.2, y: 0.1),
                            endPoint: .init(x: 0.9, y: 0.95)
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(accent.opacity(0.28), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Language

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Language")

            HStack(spacing: 5) {
                ForEach(Language.allCases) { lang in
                    languageSegment(lang)
                }
            }
            .padding(5)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.05)))
        }
    }

    private func languageSegment(_ lang: Language) -> some View {
        let selected = lang == language
        return Button {
            prefs.language = lang
        } label: {
            VStack(spacing: 3) {
                Group {
                    if lang == .arabic {
                        Text("العربية").font(Typography.arabic(18))
                    } else {
                        Text(lang.displayName).font(Typography.ui(15, weight: .semibold))
                    }
                }
                .foregroundStyle(selected ? DesignTokens.ink : DesignTokens.muted)

                Text(lang == .arabic ? "Arabic" : lang == .turkish ? "Turkish" : "Latin")
                    .font(Typography.ui(10))
                    .tracking(0.4)
                    .foregroundStyle(selected ? accent : DesignTokens.faint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? accent.opacity(0.18) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? accent.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Voice

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Voice")
            HStack(spacing: 10) {
                voiceCard(id: "hatif",   name: "Hātif",   arabic: "هاتف", tag: "VOICE",
                          desc: "Guiding voice · natural speech")
                voiceCard(id: "reciter", name: "Reciter", arabic: "قارئ", tag: "SETTINGS",
                          desc: "Choose a qārī in Settings")
            }
        }
    }

    private func voiceCard(id: String, name: String, arabic: String, tag: String, desc: String) -> some View {
        let selected = voice == id
        return Button { voice = id } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(name).font(Typography.display(20, weight: .semibold)).foregroundStyle(DesignTokens.ink)
                            Text(arabic).font(Typography.arabic(14)).foregroundStyle(selected ? accent : DesignTokens.faint)
                        }
                    }
                    Spacer()
                    Circle()
                        .fill(selected ? accent : Color.clear)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle().strokeBorder(selected ? Color.clear : Color.white.opacity(0.18), lineWidth: 1.5)
                        )
                        .shadow(color: selected ? accent.opacity(0.7) : .clear, radius: 5)
                }

                Text(tag)
                    .font(Typography.ui(9.5, weight: .semibold))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(selected ? accent : DesignTokens.faint)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(
                        Capsule().fill(selected ? accent.opacity(0.16) : Color.white.opacity(0.05))
                    )

                Text(desc)
                    .font(Typography.ui(11.5))
                    .foregroundStyle(DesignTokens.faint)
                    .lineSpacing(1.4)
                    .fixedSize(horizontal: false, vertical: true)

                // Equaliser — shown only on the active voice card
                if selected {
                    HStack(alignment: .bottom, spacing: 3) {
                        ForEach([5, 9, 6, 12, 7, 10, 5, 8, 6].indices, id: \.self) { i in
                            let h = CGFloat([5, 9, 6, 12, 7, 10, 5, 8, 6][i])
                            let dur = 0.8 + Double(i % 3) * 0.25
                            RoundedRectangle(cornerRadius: 2)
                                .fill(accent.opacity(0.55 + Double(h) / 28.0))
                                .frame(width: 3, height: h)
                                .scaleEffect(y: wavePhase ? 1.0 : 0.35, anchor: .bottom)
                                .animation(
                                    .easeInOut(duration: dur)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.09),
                                    value: wavePhase
                                )
                        }
                    }
                    .frame(height: 14, alignment: .bottom)
                    .padding(.top, 6)
                }
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(selected ? accent.opacity(0.12) : DesignTokens.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(selected ? accent.opacity(0.45) : DesignTokens.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Guidance

    private var guidanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Guidance level")
            VStack(spacing: 7) {
                ForEach(Array(GuidanceLevel.allCases.enumerated()), id: \.element) { index, level in
                    guidanceRow(index: index + 1, level: level)
                }
            }
        }
    }

    private func guidanceRow(index: Int, level: GuidanceLevel) -> some View {
        let selected = level == guidance
        return Button {
            prefs.guidanceLevel = level
        } label: {
            HStack(spacing: 12) {
                Text("\(index)")
                    .font(Typography.ui(12, weight: .bold))
                    .foregroundStyle(selected ? DesignTokens.darkOnAccent : DesignTokens.faint)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(selected ? accent : Color.clear))
                    .overlay(Circle().strokeBorder(selected ? Color.clear : Color.white.opacity(0.16), lineWidth: 1))

                VStack(alignment: .leading, spacing: 1) {
                    Text(level.displayName)
                        .font(Typography.ui(14.5, weight: .semibold))
                        .foregroundStyle(selected ? DesignTokens.ink : DesignTokens.muted)
                    Text(level.subtitle)
                        .font(Typography.ui(11.5))
                        .foregroundStyle(DesignTokens.faint)
                }

                Spacer()

                Circle()
                    .fill(selected ? accent : Color.clear)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle().strokeBorder(selected ? accent : Color.white.opacity(0.18), lineWidth: selected ? 5 : 1.5)
                    )
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? accent.opacity(0.12) : DesignTokens.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? accent.opacity(0.35) : DesignTokens.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pace

    private var paceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Pace")
            HStack(spacing: 5) {
                ForEach(PrayerPace.allCases) { p in
                    paceSegment(p)
                }
            }
            .padding(5)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.05)))
        }
    }

    private func paceSegment(_ p: PrayerPace) -> some View {
        let selected = p == pace
        let sub = p == .slow ? "Unhurried" : p == .medium ? "Balanced" : "Brisk"
        return Button {
            prefs.pace = p
        } label: {
            VStack(spacing: 3) {
                Text(p.displayName)
                    .font(Typography.ui(15, weight: .semibold))
                    .foregroundStyle(selected ? DesignTokens.ink : DesignTokens.muted)
                Text(sub)
                    .font(Typography.ui(10))
                    .foregroundStyle(selected ? accent : DesignTokens.faint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? accent.opacity(0.18) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(selected ? accent.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Waveform (extracted to avoid type-checker timeout)

    private var waveformView: some View {
        let heights: [CGFloat] = [6, 11, 8, 14, 9, 13, 7, 11, 6]
        return HStack(alignment: .bottom, spacing: 3) {
            ForEach(heights.indices, id: \.self) { i in
                let h = heights[i]
                let dur = 1.4 + Double(i % 3) * 0.4
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent.opacity(0.45 + Double(h) / 30.0))
                    .frame(width: 3, height: h)
                    .scaleEffect(y: wavePhase ? 1.0 : 0.5, anchor: .bottom)
                    .animation(.easeInOut(duration: dur).repeatForever(autoreverses: true).delay(Double(i) * 0.12), value: wavePhase)
            }
        }
        .frame(height: 14, alignment: .bottom)
        .padding(.top, 9)
        .onAppear { wavePhase = true }
    }

    // MARK: - Muezzin

    private var muezzinSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionLabel("Muezzin")
                Spacer()
                Text("Choreographs the session")
                    .font(Typography.ui(11))
                    .foregroundStyle(DesignTokens.faint)
            }

            // Featured card
            HStack(spacing: 15) {
                muezzinAvatar(muezzin, size: 56, fontSize: 25)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(muezzin.latinName)
                            .font(Typography.display(21, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)
                        Text(muezzin.arabicName)
                            .font(Typography.arabic(15))
                            .foregroundStyle(accent)
                    }
                    Text(muezzin.style)
                        .font(Typography.ui(12))
                        .foregroundStyle(DesignTokens.muted)
                        .padding(.top, 2)

                    // Animated waveform bars
                    waveformView
                }
                Spacer()
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.14), accent.opacity(0.03)],
                            startPoint: .init(x: 0.2, y: 0.1),
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(accent.opacity(0.3), lineWidth: 1)
                    )
            )

            // Picker row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Muezzins.all) { m in
                        Button { prefs.muezzinId = m.id } label: {
                            VStack(spacing: 7) {
                                muezzinAvatar(m, size: 48, fontSize: 19)
                                Text(m.latinName)
                                    .font(Typography.ui(11))
                                    .foregroundStyle(m.id == muezzinId ? accent : DesignTokens.faint)
                            }
                            .frame(width: 58)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func muezzinAvatar(_ m: Muezzin, size: CGFloat, fontSize: CGFloat) -> some View {
        let selected = m.id == muezzinId
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [accent.opacity(0.38), Color.white.opacity(0.04)],
                        center: .init(x: 0.4, y: 0.32),
                        startRadius: 0, endRadius: size * 0.82
                    )
                )
            Text(m.arabicInitial)
                .font(Typography.arabic(fontSize))
                .foregroundStyle(DesignTokens.ink)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().strokeBorder(
                selected ? accent : Color.white.opacity(0.12),
                lineWidth: selected ? 2 : 1
            )
        )
        .shadow(color: selected ? accent.opacity(0.5) : .clear, radius: selected ? 10 : 0)
    }

    // MARK: - Footer

    private var startFooter: some View {
        VStack(spacing: 11) {
            Text("\(salat.displayName) · \(guidance.displayName) · \(pace.displayName) pace · \(muezzin.latinName)")
                .font(Typography.ui(11.5))
                .tracking(0.3)
                .foregroundStyle(DesignTokens.faint)
                .multilineTextAlignment(.center)

            Button {
                prefs.salatType       = salat
                prefs.selectedUnitIds = unitIds
                prefs.language        = language
                prefs.guidanceLevel   = guidance
                prefs.pace            = pace
                prefs.muezzinId       = muezzinId
                onBegin(salat, unitIds, language, guidance, pace, muezzinId)
            } label: {
                HStack(spacing: 9) {
                    Text("Begin \(salat.displayName)")
                        .font(Typography.ui(16, weight: .bold))
                        .tracking(0.3)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(DesignTokens.darkOnAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: accent.opacity(0.34), radius: 17, y: 12)
            }
            .buttonStyle(.plain)
            .disabled(!isAvailable)
            .opacity(isAvailable ? 1 : 0.4)
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 26)
    }

    // MARK: - Section label helper

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Typography.eyebrow)
            .tracking(2.5)
            .textCase(.uppercase)
            .foregroundStyle(DesignTokens.faint)
    }
}

// MARK: - Previews

#Preview("Maghrib") { SetupPreview(salat: .maghrib) }
#Preview("Fajr")    { SetupPreview(salat: .fajr) }
#Preview("Isha")    { SetupPreview(salat: .isha) }
#Preview("Dhuhr")   { SetupPreview(salat: .dhuhr) }
#Preview("Asr")     { SetupPreview(salat: .asr) }

private struct SetupPreview: View {
    let salat: SalatType
    var body: some View {
        PrayerSetupView(isAvailable: true) { _, _, _, _, _, _ in }
    }
}
