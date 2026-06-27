import SwiftUI

// MARK: - Settings screen
// Source of truth: docs/features/settings/SPEC.md + docs/features/settings/settings.html
//
// A themed master/detail flow: Main → Prayer Alerts / Advanced. Dark palette with
// the accent driven by the current prayer; per-prayer rows use that prayer's accent.

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    private let accent = SettingsPalette.accent
    private let navAnim = Animation.easeInOut(duration: 0.28)
    private let expandAnim = Animation.easeInOut(duration: 0.22)

    var body: some View {
        ZStack {
            SettingsPalette.background.ignoresSafeArea()

            ScrollBehindScreen(scrim: Color(hex: "#1a1730")) {
                header
            } content: {
                Group {
                    switch viewModel.screen {
                    case .main:     mainScreen
                    case .alerts:   alertsScreen
                    case .advanced: advancedScreen
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        ScreenHeader(
            eyebrow: eyebrow,
            title: title,
            accent: accent,
            ink: SettingsPalette.ink,
            leading: { if viewModel.screen != .main { backButton } }
        )
    }

    private var backButton: some View {
        Button {
            withAnimation(navAnim) { viewModel.goBack() }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(SettingsPalette.muted)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.06)))
                .overlay(Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var eyebrow: String {
        switch viewModel.screen {
        case .main:     return "Preferences"
        case .alerts:   return "Notifications"
        case .advanced: return "Configuration"
        }
    }

    private var title: String {
        switch viewModel.screen {
        case .main:     return "Settings"
        case .alerts:   return "Prayer Alerts"
        case .advanced: return "Advanced"
        }
    }

    // MARK: - Main screen

    private var mainScreen: some View {
        VStack(spacing: 10) {
            mainNavRow(icon: "bell", title: "Prayer Alerts",
                       subtitle: "Adhan reminders & recitations") {
                withAnimation(navAnim) { viewModel.go(to: .alerts) }
            }
            mainNavRow(icon: "slider.horizontal.3", title: "Advanced",
                       subtitle: "Methods, offsets & language") {
                withAnimation(navAnim) { viewModel.go(to: .advanced) }
            }
        }
    }

    private func mainNavRow(icon: String, title: String, subtitle: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(accent)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(accent.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).strokeBorder(accent.opacity(0.25), lineWidth: 1))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Typography.ui(15, weight: .semibold))
                        .foregroundStyle(SettingsPalette.ink)
                    Text(subtitle)
                        .font(Typography.ui(12))
                        .foregroundStyle(SettingsPalette.faint)
                }
                Spacer()
                SettingsChevron()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(colors: [accent.opacity(0.10), accent.opacity(0.03)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(accent.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Prayer Alerts screen

    private var alertsScreen: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Ramadan
            VStack(alignment: .leading, spacing: 10) {
                SettingsSectionLabel(text: "Ramadan")
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Suhoor ending reminder")
                            .font(Typography.ui(14.5, weight: .semibold))
                            .foregroundStyle(SettingsPalette.ink)
                        Text("Alert 15 minutes before Suhoor ends")
                            .font(Typography.ui(11.5))
                            .foregroundStyle(SettingsPalette.faint)
                    }
                    Spacer()
                    SettingsToggle(isOn: $viewModel.suhoorReminder, accent: accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .settingsCard()
            }

            // Per Prayer
            VStack(alignment: .leading, spacing: 10) {
                SettingsSectionLabel(text: "Per Prayer")
                VStack(spacing: 6) {
                    ForEach(PrayerTime.allCases) { prayer in
                        alertRow(prayer)
                    }
                }
            }
        }
    }

    private func alertRow(_ prayer: PrayerTime) -> some View {
        let pAccent = prayer.theme.accent
        let expanded = viewModel.expandedAlertPrayer == prayer
        return VStack(spacing: 0) {
            Button {
                withAnimation(expandAnim) { viewModel.toggleExpandedAlert(prayer) }
            } label: {
                HStack(spacing: 12) {
                    prayerNameLabel(prayer)
                    Spacer()
                    if viewModel.isAlertEnabled(prayer) { onTag(pAccent) }
                    SettingsChevron(rotated: expanded)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider().overlay(pAccent.opacity(0.18))

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pre-Adhan reminder")
                                .font(Typography.ui(13.5, weight: .semibold))
                                .foregroundStyle(SettingsPalette.ink)
                            Text("Gentle knock 30 minutes before the prayer starts")
                                .font(Typography.ui(11))
                                .foregroundStyle(SettingsPalette.faint)
                        }
                        Spacer()
                        SettingsToggle(isOn: alertBinding(prayer), accent: pAccent)
                    }

                    SettingsSectionLabel(text: "Recitation")
                    VStack(spacing: 4) {
                        ForEach(Reciter.all) { rec in
                            SettingsOptionRow(
                                label: rec.name,
                                arabic: rec.arabic,
                                selected: viewModel.reciter(for: prayer) == rec.id,
                                accent: pAccent
                            ) {
                                viewModel.setReciter(rec.id, for: prayer)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(expanded ? pAccent.opacity(0.06) : SettingsPalette.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(expanded ? pAccent.opacity(0.28) : SettingsPalette.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Advanced screen

    private var advancedScreen: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Prayer Methods
            VStack(alignment: .leading, spacing: 10) {
                SettingsSectionLabel(text: "Prayer Methods")
                VStack(spacing: 6) {
                    calculationMethodRow
                    fajrMethodRow
                    sunriseMethodRow
                    asrMethodRow
                    ishaMethodRow
                    qiyamRow
                }
            }

            // Time Adjustments
            VStack(alignment: .leading, spacing: 10) {
                SettingsSectionLabel(text: "Prayer Time Adjustments")
                VStack(spacing: 5) {
                    ForEach(PrayerTime.allCases) { prayer in
                        offsetRow(prayer)
                    }
                }
            }

            // Hijri Calendar
            VStack(alignment: .leading, spacing: 10) {
                SettingsSectionLabel(text: "Hijri Calendar")
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Adjust Hijri date")
                            .font(Typography.ui(14.5, weight: .semibold))
                            .foregroundStyle(SettingsPalette.ink)
                        Text("Offset from calculated date")
                            .font(Typography.ui(11.5))
                            .foregroundStyle(SettingsPalette.faint)
                    }
                    Spacer()
                    SettingsStepper(display: viewModel.hijriLabel,
                                    onMinus: { viewModel.adjustHijri(-1) },
                                    onPlus:  { viewModel.adjustHijri(1) })
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .settingsCard()
            }

            // Language
            VStack(alignment: .leading, spacing: 10) {
                SettingsSectionLabel(text: "Language")
                VStack(spacing: 5) {
                    ForEach(Language.allCases) { language in
                        languageRow(language)
                    }
                }
            }

            // Rate
            rateRow
        }
    }

    // MARK: Method rows

    private var calculationMethodRow: some View {
        methodCard(.calculation, name: "Calculation", arabic: nil,
                   currentLabel: viewModel.calc.method.displayName, accent: accent) {
            ForEach(CalculationMethod.selectable, id: \.self) { method in
                SettingsOptionRow(label: method.displayName,
                                  selected: viewModel.calc.method == method,
                                  accent: accent) {
                    viewModel.calc.method = method
                    withAnimation(expandAnim) { viewModel.expandedMethodRow = nil }
                }
            }
        }
    }

    private var fajrMethodRow: some View {
        let pAccent = PrayerTime.fajr.theme.accent
        return methodCard(.fajr, name: "Fajr", arabic: PrayerTime.fajr.arabicName,
                          currentLabel: viewModel.calc.fajrRule.displayName, accent: pAccent) {
            ForEach(FajrRule.allCases) { rule in
                SettingsOptionRow(label: rule.displayName,
                                  detail: rule == .normal ? "Use the master time" : "Earlier calculation method",
                                  selected: viewModel.calc.fajrRule == rule,
                                  accent: pAccent) {
                    viewModel.calc.fajrRule = rule
                    withAnimation(expandAnim) { viewModel.expandedMethodRow = nil }
                }
            }
        }
    }

    private var sunriseMethodRow: some View {
        let pAccent = PrayerTime.dhuhr.theme.accent
        return methodCard(.sunrise, name: "Sunrise", arabic: "الشروق",
                          currentLabel: viewModel.sunriseDoha ? "Doha" : "Normal", accent: pAccent) {
            SettingsOptionRow(label: "Normal", detail: "Use the master time",
                              selected: !viewModel.sunriseDoha, accent: pAccent) {
                viewModel.sunriseDoha = false
                withAnimation(expandAnim) { viewModel.expandedMethodRow = nil }
            }
            SettingsOptionRow(label: "Doha", detail: "Extended Ishrāq time window",
                              selected: viewModel.sunriseDoha, accent: pAccent) {
                viewModel.sunriseDoha = true
                withAnimation(expandAnim) { viewModel.expandedMethodRow = nil }
            }
        }
    }

    private var asrMethodRow: some View {
        let pAccent = PrayerTime.asr.theme.accent
        return methodCard(.asr, name: "Asr", arabic: PrayerTime.asr.arabicName,
                          currentLabel: viewModel.calc.madhab.displayName, accent: pAccent) {
            ForEach(Madhab.allCases, id: \.self) { madhab in
                SettingsOptionRow(label: madhab.displayName,
                                  detail: madhab.detail,
                                  selected: viewModel.calc.madhab == madhab,
                                  accent: pAccent) {
                    viewModel.calc.madhab = madhab
                    withAnimation(expandAnim) { viewModel.expandedMethodRow = nil }
                }
            }
        }
    }

    private var ishaMethodRow: some View {
        let pAccent = PrayerTime.isha.theme.accent
        return methodCard(.isha, name: "Isha", arabic: PrayerTime.isha.arabicName,
                          currentLabel: viewModel.ishaRule.label, accent: pAccent) {
            ForEach(IshaRuleUI.allCases) { rule in
                SettingsOptionRow(label: rule.label, detail: rule.desc,
                                  selected: viewModel.ishaRule == rule,
                                  accent: pAccent) {
                    viewModel.ishaRule = rule
                    withAnimation(expandAnim) { viewModel.expandedMethodRow = nil }
                }
            }
        }
    }

    private var qiyamRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Qiyam")
                    .font(Typography.ui(15, weight: .semibold))
                    .foregroundStyle(SettingsPalette.ink)
                Text("Show Qiyam time in prayer list")
                    .font(Typography.ui(11.5))
                    .foregroundStyle(SettingsPalette.faint)
            }
            Spacer()
            SettingsToggle(isOn: $viewModel.qiyamOn, accent: accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .settingsCard()
    }

    @ViewBuilder
    private func methodCard<Content: View>(_ row: AdvancedMethodRow, name: String, arabic: String?,
                                           currentLabel: String, accent pAccent: Color,
                                           @ViewBuilder options: () -> Content) -> some View {
        let expanded = viewModel.expandedMethodRow == row
        VStack(spacing: 0) {
            Button {
                withAnimation(expandAnim) { viewModel.toggleExpandedMethod(row) }
            } label: {
                HStack(spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(name)
                            .font(Typography.ui(15, weight: .semibold))
                            .foregroundStyle(SettingsPalette.ink)
                        if let arabic {
                            Text(arabic)
                                .font(Typography.arabic(14))
                                .environment(\.layoutDirection, .rightToLeft)
                                .foregroundStyle(SettingsPalette.faint)
                        }
                    }
                    Spacer()
                    Text(currentLabel)
                        .font(Typography.ui(12, weight: .semibold))
                        .foregroundStyle(pAccent)
                        .lineLimit(1)
                    SettingsChevron(rotated: expanded)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 5) {
                    options()
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(expanded ? pAccent.opacity(0.06) : SettingsPalette.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(expanded ? pAccent.opacity(0.28) : SettingsPalette.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: Offset / language / rate rows

    private func offsetRow(_ prayer: PrayerTime) -> some View {
        HStack(spacing: 12) {
            prayerNameLabel(prayer, size: 14.5)
            Spacer()
            SettingsStepper(display: viewModel.offsetLabel(for: prayer),
                            onMinus: { viewModel.adjustOffset(-1, for: prayer) },
                            onPlus:  { viewModel.adjustOffset(1, for: prayer) })
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .settingsCard()
    }

    private func languageRow(_ language: Language) -> some View {
        let selected = viewModel.prefs.language == language
        return Button {
            viewModel.prefs.language = language
        } label: {
            HStack(spacing: 12) {
                SettingsRadio(selected: selected, accent: accent)
                Group {
                    if language == .arabic {
                        Text(language.displayName).font(Typography.arabic(18))
                    } else {
                        Text(language.displayName).font(Typography.ui(14, weight: .semibold))
                    }
                }
                .foregroundStyle(selected ? SettingsPalette.ink : SettingsPalette.muted)
                Spacer()
                Text(languageSubtitle(language))
                    .font(Typography.ui(11))
                    .foregroundStyle(selected ? accent : SettingsPalette.faint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .settingsCard(
                fill: selected ? accent.opacity(0.10) : SettingsPalette.cardFill,
                border: selected ? accent.opacity(0.35) : SettingsPalette.hairline
            )
        }
        .buttonStyle(.plain)
    }

    private func languageSubtitle(_ language: Language) -> String {
        switch language {
        case .english: return "Default"
        case .turkish: return "Turkish"
        case .arabic:  return "Arabic"
        }
    }

    private var rateRow: some View {
        Button {
            viewModel.rateApp()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "star")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(accent)
                Text("Rate SalahMotion")
                    .font(Typography.ui(14.5, weight: .semibold))
                    .foregroundStyle(SettingsPalette.ink)
                Spacer()
                SettingsChevron()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .settingsCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Shared bits

    private func prayerNameLabel(_ prayer: PrayerTime, size: CGFloat = 15) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(prayer.displayName)
                .font(Typography.ui(size, weight: .semibold))
                .foregroundStyle(SettingsPalette.ink)
            Text(prayer.arabicName)
                .font(Typography.arabic(size - 1))
                .environment(\.layoutDirection, .rightToLeft)
                .foregroundStyle(SettingsPalette.faint)
        }
    }

    private func onTag(_ color: Color) -> some View {
        Text("ON")
            .font(.system(size: 10, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.15)))
    }

    private func alertBinding(_ prayer: PrayerTime) -> Binding<Bool> {
        Binding(
            get: { viewModel.isAlertEnabled(prayer) },
            set: { viewModel.setAlert($0, for: prayer) }
        )
    }
}

#Preview {
    SettingsView()
}
