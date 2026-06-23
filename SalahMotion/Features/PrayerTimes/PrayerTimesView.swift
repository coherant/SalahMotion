import SwiftUI

struct PrayerTimesView: View {

    @State private var vm = PrayerTimesViewModel()
    @State private var enabledNotifications: Set<String> = NotificationManager.enabledPrayers()
    @State private var ctaPulsing = false

    private var prayerTime: PrayerTime { vm.prayerTime }
    private var theme: PrayerTimeTheme { prayerTime.theme }
    private var accent: Color { theme.accent }
    private var ink: Color { theme.ink }
    private var muted: Color { theme.muted }
    private var faint: Color { theme.faint }
    private var isLight: Bool { theme.isLight }

    // Neutral colours that adapt to light (Dhuhr) vs dark themes
    private var neutralFill: Color {
        isLight ? Color(hex: "#2b3a4a").opacity(0.12) : Color.white.opacity(0.05)
    }
    private var neutralBorder: Color {
        isLight ? Color(hex: "#2b3a4a").opacity(0.20) : Color.white.opacity(0.14)
    }
    private var neutralText: Color {
        isLight ? Color(hex: "#2b3a4a").opacity(0.55) : Color.white.opacity(0.6)
    }

    var body: some View {
        ZStack {
            prayerTime.backgroundGradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 8)
                    upNextCard
                        .padding(.top, 22)
                    prayerList
                        .padding(.top, 22)
                    ctaButton
                        .padding(.top, 18)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 110)
            }
        }
        .onAppear { vm.location.requestLocation() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(vm.hijriDate) · \(prayerTime.phase)")
                    .eyebrowStyle()
                    .tracking(1.5)
                    .foregroundStyle(accent)
                Text(vm.gregorianDate)
                    .font(Typography.display(27, weight: .medium))
                    .foregroundStyle(ink)
            }
            Spacer()
            locationPill.padding(.top, 4)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private var locationPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 7))
                .foregroundStyle(isLight ? Color(hex: "#2b3a4a").opacity(0.6) : Color(hex: "#c8b3a8"))
            Text(vm.cityName)
                .font(Typography.ui(9))
                .foregroundStyle(isLight ? Color(hex: "#2b3a4a").opacity(0.75) : Color(hex: "#d8d0ca"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(isLight ? Color.white.opacity(0.6) : Color.white.opacity(0.05))
                .overlay(Capsule().strokeBorder(
                    isLight ? Color(hex: "#2b3a4a").opacity(0.1) : Color.white.opacity(0.08),
                    lineWidth: 1
                ))
        )
    }

    // MARK: - Up-next card

    private var upNextCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Up next")
                        .eyebrowStyle()
                        .tracking(2.5)
                        .foregroundStyle(neutralText)
                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        Text(prayerTime.arabic)
                            .arabicStyle(size: 34)
                            .foregroundStyle(ink)
                        Text(prayerTime.displayName)
                            .font(Typography.display(26, weight: .medium))
                            .foregroundStyle(muted)
                    }
                    .padding(.top, 8)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(vm.countdown)
                        .font(Typography.ui(18, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(prayerTime.displayTime)
                        .font(Typography.ui(13))
                        .foregroundStyle(isLight ? Color(hex: "#2b3a4a").opacity(0.5) : Color.white.opacity(0.5))
                }
            }
            dayRail.padding(.top, 18)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [accent.opacity(0.16), accent.opacity(0.04)],
                    startPoint: UnitPoint(x: 0.15, y: 0),
                    endPoint: UnitPoint(x: 0.85, y: 1)
                ))
                .overlay(RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(accent.opacity(0.24), lineWidth: 1))
        )
    }

    // MARK: - Day progress rail

    // x-positions of the 5 prayer nodes as fractions of rail width
    private let nodePositions: [Double] = [0.05, 0.38, 0.56, 0.72, 0.90]

    private var dayRail: some View {
        let currentIndex = PrayerTime.allCases.firstIndex(of: prayerTime) ?? 0
        let fill = vm.continuousRailFill

        return GeometryReader { geo in
            let w = geo.size.width
            let neutralRing: Color = isLight
                ? Color(hex: "#2b3a4a").opacity(0.28)
                : Color.white.opacity(0.30)

            ZStack(alignment: .topLeading) {
                // Track
                Rectangle()
                    .fill(isLight ? Color(hex: "#2b3a4a").opacity(0.12) : Color.white.opacity(0.10))
                    .frame(width: w, height: 1.5)
                    .offset(y: 12)

                // Fill
                Rectangle()
                    .fill(accent)
                    .frame(width: w * fill, height: 1.5)
                    .offset(y: 12)

                // Prayer nodes
                ForEach(Array(nodePositions.enumerated()), id: \.offset) { i, pos in
                    if i < currentIndex {
                        // Prayed — filled solid dot
                        Circle()
                            .fill(accent)
                            .frame(width: 9, height: 9)
                            .offset(x: w * pos - 4.5, y: 8)
                    } else {
                        // Current or future — hollow ring
                        Circle()
                            .strokeBorder(neutralRing, lineWidth: 1.5)
                            .frame(width: 8, height: 8)
                            .offset(x: w * pos - 4, y: 9)
                    }
                }

                // Active pulse marker — sits at end of fill line
                PulseMarker(accent: accent)
                    .frame(width: 23, height: 23)
                    .offset(x: w * fill - 11.5, y: 1)
            }
        }
        .frame(height: 26)
    }

    // MARK: - Prayer list

    private var prayerList: some View {
        VStack(spacing: 2) {
            ForEach(PrayerTime.allCases) { prayer in
                prayerRow(prayer)
            }
        }
    }

    private func prayerRow(_ prayer: PrayerTime) -> some View {
        let allCases = PrayerTime.allCases
        let currentIndex = allCases.firstIndex(of: prayerTime) ?? 0
        let rowIndex = allCases.firstIndex(of: prayer) ?? 0
        let isPast = rowIndex < currentIndex
        let isCurrent = rowIndex == currentIndex

        return HStack(spacing: 13) {
            statusDot(isPast: isPast, isCurrent: isCurrent)

            HStack(alignment: .lastTextBaseline, spacing: 9) {
                Text(prayer.displayName)
                    .font(Typography.ui(16, weight: isCurrent ? .semibold : .regular))
                    .foregroundStyle(
                        isCurrent ? ink
                        : isPast ? muted.opacity(0.85)
                        : faint
                    )
                Text(prayer.arabic)
                    .arabicStyle(size: 16)
                    .foregroundStyle(
                        isCurrent ? muted
                        : isPast ? faint.opacity(0.65)
                        : faint.opacity(0.55)
                    )
            }

            Spacer()

            Text(prayer.displayTime)
                .font(Typography.ui(15, weight: isCurrent ? .semibold : .regular))
                .foregroundStyle(
                    isCurrent ? accent
                    : isPast ? faint.opacity(0.65)
                    : faint.opacity(0.55)
                )

            notificationBell(prayer: prayer)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, isCurrent ? 13 : 11)
        .background(
            Group {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isLight ? Color.white.opacity(0.55) : Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(accent.opacity(isLight ? 0.28 : 0.20), lineWidth: 1))
                }
            }
        )
    }

    @ViewBuilder
    private func statusDot(isPast: Bool, isCurrent: Bool) -> some View {
        ZStack {
            if isPast {
                Circle()
                    .fill(accent.opacity(isLight ? 0.18 : 0.20))
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accent)
            } else if isCurrent {
                Circle()
                    .strokeBorder(accent, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .shadow(color: accent.opacity(0.45), radius: 6)
            } else {
                Circle()
                    .strokeBorder(neutralBorder, lineWidth: 1.5)
                    .frame(width: 24, height: 24)
            }
        }
        .frame(width: 24, height: 24)
    }

    // MARK: - Notification bell toggle

    private func notificationBell(prayer: PrayerTime) -> some View {
        let on = enabledNotifications.contains(prayer.rawValue)
        return Button {
            NotificationManager.toggle(prayer)
            enabledNotifications = NotificationManager.enabledPrayers()
        } label: {
            ZStack {
                Circle()
                    .fill(on ? accent.opacity(0.18) : accent.opacity(0.04))
                    .frame(width: 24, height: 24)
                Circle()
                    .strokeBorder(
                        on ? accent.opacity(0.55) : neutralBorder,
                        lineWidth: 1.5
                    )
                    .frame(width: 24, height: 24)
                Image(systemName: "bell.fill")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(on ? accent : faint.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: on)
    }

    // MARK: - CTA button

    private var ctaButton: some View {
        let label = vm.isInPrayerWindow
            ? "Pray \(prayerTime.displayName)"
            : (prayerTime == .isha ? "Begin Isha" : "Prepare for \(prayerTime.displayName)")

        return Button { } label: {
            Text(label)
                .font(Typography.eyebrow)
                .tracking(1.5)
                .foregroundStyle(accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .strokeBorder(accent.opacity(0.5), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if vm.isInPrayerWindow {
                            Capsule()
                                .fill(accent)
                                .scaleEffect(
                                    x: ctaPulsing ? 1.12 : 1.0,
                                    y: ctaPulsing ? 1.5  : 1.0
                                )
                                .opacity(ctaPulsing ? 0 : 0.35)
                                .animation(
                                    .easeOut(duration: 3.6).repeatForever(autoreverses: false),
                                    value: ctaPulsing
                                )
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .onAppear { ctaPulsing = vm.isInPrayerWindow }
        .onChange(of: vm.isInPrayerWindow) { ctaPulsing = vm.isInPrayerWindow }
    }
}

// MARK: - Pulse marker

private struct PulseMarker: View {
    let accent: Color
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(accent, lineWidth: 1)
                .scaleEffect(pulsing ? 1.5 : 0.85)
                .opacity(pulsing ? 0 : 0.55)
                .animation(
                    .easeOut(duration: 3.6).repeatForever(autoreverses: false),
                    value: pulsing
                )
            Circle()
                .fill(accent)
                .frame(width: 13, height: 13)
                .shadow(color: accent.opacity(0.9), radius: 7)
        }
        .onAppear { pulsing = true }
    }
}

// MARK: - Previews

#Preview("Fajr")    { PrayerTimesView() }
#Preview("Isha")    { PrayerTimesView() }
