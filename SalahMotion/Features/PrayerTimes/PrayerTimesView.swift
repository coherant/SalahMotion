import SwiftUI
import CoreLocation

struct PrayerTimesView: View {

    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @State private var vm = PrayerTimesViewModel()
    @State private var enabledNotifications: Set<String> = NotificationManager.enabledPrayers()
    @State private var ctaPulsing = false
    @State private var timeMachine = TimeMachine.shared
    @State private var weather = WeatherStore()   // ambient; behind FeatureFlags.weather

    // Time-based cross-fade (theme.md §9): tokens + background interpolate between
    // periods over real-time-anchored windows. `now` ticks each second (VM timer),
    // so the fade is continuous.
    // "Now" shifted by the time-machine egg (0 normally). Drives theme + celestial.
    private var displayNow: Date { vm.now.addingTimeInterval(timeMachine.offset) }
    private var blend: ThemeBlend { DayTheme.blend(at: displayNow) }
    private var prayerTime: PrayerTime { blend.dominant }   // for .phase / labels
    private var theme: PrayerTimeTheme { blend.theme }
    private var accent: Color { theme.accent }
    private var ink: Color { theme.ink }
    private var muted: Color { theme.muted }
    private var faint: Color { theme.faint }
    private var isLight: Bool { theme.isLight }

    private let cardCorner: CGFloat = 24

    // Celestial complication — real Sun (Adhan) + real Moon (SwiftAA) at the
    // current time, driven by the engine's coordinate (Melbourne until the device
    // reports).
    private var celestialSky: CelestialSky {
        let engine = PrayerTimesEngine.shared
        let c = engine.coordinate
        // Pass the LOCATION's timezone so the solar arc brackets the day correctly
        // (a UTC-day boundary mid-morning was snapping the sun to the horizon).
        let location = ObserverLocation(latitude: c.latitude,
                                        longitude: c.longitude,
                                        timeZone: engine.timeZone)
        return .live(location: location)
    }
    // Animate only while this tab is foreground & active.
    private var isCelestialActive: Bool {
        router.selectedTab == .prayerTimes && scenePhase == .active
    }


    // Daylight factor (0…1) for the ambient sky birds, from the REAL sun (vm.now,
    // not displayNow) so the time-machine egg sweeps the sun/theme but leaves the
    // birds flying. 1 around solar noon, easing to 0 at the horizon and at night.
    private var birdDaylight: Double {
        let phase = celestialSky.sun.sky(at: vm.now, location: celestialSky.location).dayPhase
        guard phase <= 0.5 else { return 0 }            // night
        let altitude = sin(.pi * phase / 0.5)           // 0 at horizon, 1 at transit
        return min(1, max(0, altitude / 0.35))          // full once the sun is well up
    }

    // Darkness (1 = deep night) for the meteor layer — the inverse of daylight, so
    // birds fade out and meteors fade in around dusk. Engages once the sun is well
    // down (daylight < 0.1), handing the sky over to the starfield + the occasional
    // shooting star.
    private var nightFactor: Double { 1 - min(1, birdDaylight / 0.1) }

    // MARK: - Meteor shower (Tier 2)

    private var locationCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = PrayerTimesEngine.shared.timeZone
        return cal
    }

    /// Project a shower's radiant to a normalized screen point in the upper sky, or
    /// nil if it's below ~8° altitude (not worth showing). Altitude → height,
    /// azimuth → a stylised east-west x (E left, matching the celestial arc).
    private func radiantScreenPoint(_ shower: MeteorShower) -> CGPoint? {
        let (alt, az) = MeteorShowers.radiantAltAz(shower, location: celestialSky.location, date: vm.now)
        guard alt > 8 else { return nil }
        let y = max(0.04, min(0.5, 0.5 - (alt / 90) * 0.42))   // horizon→0.5, zenith→~0.08
        let x = 0.5 - 0.42 * sin(az * .pi / 180)
        return CGPoint(x: x, y: y)
    }

    /// The active shower for the meteor layer: the egg (stage 3) forces one on
    /// demand regardless of date; otherwise a real shower inside its date window
    /// whose radiant is above the horizon for this location.
    private var meteorShowerContext: MeteorShowerContext {
        if timeMachine.meteorShowerActive {
            let shower = MeteorShowers.active(on: vm.now, calendar: locationCalendar)
                      ?? MeteorShowers.nearest(to: vm.now, calendar: locationCalendar)
            let radiant = radiantScreenPoint(shower) ?? CGPoint(x: 0.5, y: 0.14)   // fallback upper-centre
            return MeteorShowerContext(radiant: radiant, rate: 30)
        }
        if let shower = MeteorShowers.active(on: vm.now, calendar: locationCalendar),
           let radiant = radiantScreenPoint(shower) {
            return MeteorShowerContext(radiant: radiant, rate: max(6, shower.zhr / 8))
        }
        return .none
    }

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
        // Structurally identical to CalibrationView (the proven-on-device static
        // screen): gradient as a ZStack sibling, header at the top of the VStack.
        // No .safeAreaPadding / .padding(.bottom,) — those were the divergence that
        // mispositioned the header on device while the simulator looked fine.
        ZStack {
            blend.background.ignoresSafeArea()

            // Aurora — glows over the night sky/starfield, beneath birds & meteors.
            // The egg's stage-4 forces it on demand any time. See aurora.md.
            AuroraView(isActive: isCelestialActive,
                       night: timeMachine.auroraActive ? 1 : nightFactor,
                       forced: timeMachine.auroraActive)
                .ignoresSafeArea()

            // Ambient sky birds — far back, behind every fixture, glimpsed in the
            // open sky around the header and between cards. See ambient-sky-birds.md.
            SkyBirdsView(isActive: isCelestialActive, tint: ink, daylight: birdDaylight,
                         murmuration: timeMachine.murmurationActive)
                .ignoresSafeArea()

            // Night meteors — the after-dark counterpart to the birds; a rare
            // shooting star among the stars. See night-meteors.md.
            // The egg's stage-3 shower forces darkness so it shows on demand any time.
            NightMeteorsView(isActive: isCelestialActive,
                             night: timeMachine.meteorShowerActive ? 1 : nightFactor,
                             tint: ink,
                             shower: meteorShowerContext)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header   // ScreenHeader owns its own 22pt gutter + top padding

                VStack(spacing: 0) {
                    upNextCard
                        .padding(.top, 22)
                    prayerList
                        .padding(.top, 22)

                    // Weather — glanceable, bottom-right under the last prayer row,
                    // themed by the current time of day. Tap the capsule to cycle
                    // conditions (dev/demo), starting at sunny. See weather/SPEC.md §5.
                    if FeatureFlags.weather {
                        HStack {
                            Spacer()
                            Button { weather.cycleManual() } label: {
                                WeatherChip(state: weather.displayState,
                                            ink: ink, muted: muted, accent: accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        Capsule()
                                            .fill(neutralFill)
                                            .overlay(Capsule().strokeBorder(neutralBorder, lineWidth: 1))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 46)   // ≈ 8 mm below the last prayer row
                    }

                    Spacer()
                    ctaButton
                        .padding(.bottom, 32)
                }
                .padding(.horizontal, 22)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                // Weather effects — painted BEHIND the content as a true backdrop, so
                // the Metal-backed SpriteView can't composite above the rows. Opacity
                // halved for subtlety. Driven by the same state the pill cycles.
                if FeatureFlags.weather {
                    WeatherLayerView(state: weather.displayState,
                                     isActive: isCelestialActive, tint: ink)
                        .opacity(0.5)
                        .ignoresSafeArea()
                }
            }
        }
        .onAppear { vm.location.requestLocation() }
    }

    // MARK: - Header

    private var header: some View {
        ScreenHeader(
            eyebrow: "\(vm.hijriDate) · \(prayerTime.phase)",
            title: vm.gregorianDate,
            accent: accent,
            ink: ink,
            trailing: { locationPill }
        )
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
        // Hidden egg: long-press the location capsule → straight into the rewind,
        // with a heavy haptic at the moment it fires (replacing the one the
        // context menu used to give).
        .onLongPressGesture {
            timeMachine.play()
        }
        .sensoryFeedback(trigger: timeMachine.isRunning) { _, isRunning in
            isRunning ? .impact(weight: .heavy) : nil
        }
        // Stage 2 (murmuration) gets its own heavy thump as the flock floods in.
        .sensoryFeedback(trigger: timeMachine.murmurationActive) { _, active in
            active ? .impact(weight: .heavy) : nil
        }
        // Stage 3 (meteor shower) likewise.
        .sensoryFeedback(trigger: timeMachine.meteorShowerActive) { _, active in
            active ? .impact(weight: .heavy) : nil
        }
        // Stage 4 (aurora) likewise.
        .sensoryFeedback(trigger: timeMachine.auroraActive) { _, active in
            active ? .impact(weight: .heavy) : nil
        }
    }

    // MARK: - Up-next card

    private var upNextCard: some View {
        // Evaluated at displayNow so the card visibly rewinds during the egg
        // (the prayer list below stays on real time).
        let up = vm.upNext(at: displayNow)
        let countdownText = vm.countdown(at: displayNow)
        return VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Up next")
                        .eyebrowStyle()
                        .tracking(2.5)
                        .foregroundStyle(neutralText)
                    HStack(alignment: .lastTextBaseline, spacing: 10) {
                        Text(up.prayer.arabic)
                            .arabicStyle(size: 34)
                            .foregroundStyle(ink)
                            .lineLimit(1)
                        Text(up.prayer.displayName)
                            .font(Typography.display(26, weight: .medium))
                            .foregroundStyle(muted)
                            .lineLimit(1)
                    }
                    .padding(.top, 8)
                }
                .layoutPriority(1)   // name keeps full size; the countdown yields width
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(countdownText)
                        .font(Typography.ui(18, weight: .semibold))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                    Text(up.prayer.displayTime)
                        .font(Typography.ui(13))
                        .foregroundStyle(isLight ? Color(hex: "#2b3a4a").opacity(0.5) : Color.white.opacity(0.5))
                }
            }
            dayRail.padding(.top, 18)
        }
        .padding(20)
        .background(
            // Single clip authority (§3): gradient + celestial bodies clipped to
            // the card silhouette, the stroke laid on AFTER the clip. The arc sits
            // in the background, behind every fixture above.
            ZStack {
                RoundedRectangle(cornerRadius: cardCorner)
                    .fill(LinearGradient(
                        colors: [accent.opacity(0.16), accent.opacity(0.04)],
                        startPoint: UnitPoint(x: 0.15, y: 0),
                        endPoint: UnitPoint(x: 0.85, y: 1)
                    ))
                CelestialArcView(sky: celestialSky,
                                 now: vm.now,
                                 isActive: isCelestialActive,
                                 timeOffset: timeMachine.offset,
                                 isWarping: timeMachine.isRunning)
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCorner))
            .overlay(RoundedRectangle(cornerRadius: cardCorner)
                .strokeBorder(accent.opacity(0.24), lineWidth: 1))
        )
    }

    // MARK: - Day progress rail

    // x-positions of the 5 prayer nodes as fractions of rail width
    private let nodePositions: [Double] = [0.05, 0.38, 0.56, 0.72, 0.90]

    private var dayRail: some View {
        let currentIndex = vm.currentPrayerIndex
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
        let currentIndex = vm.currentPrayerIndex
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
        let label = vm.ctaLabel

        return Button {
            if vm.isInPrayerWindow { router.selectedTab = .guided }
        } label: {
            Text(label)
                .font(Typography.eyebrow)
                .tracking(1.5)
                // Actionable → filled accent pill with dark ink (readable on any
                // background, incl. Asr's warm horizon glow). Inactive → ghost
                // outline. Crisp surfaces only, no scrim. See theme.md §1 (Asr).
                .foregroundStyle(vm.isInPrayerWindow ? Color(hex: "#16142a") : accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(vm.isInPrayerWindow ? accent : Color.clear)
                        .overlay(Capsule().strokeBorder(accent.opacity(0.5), lineWidth: 1))
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
        .opacity(vm.isInPrayerWindow ? 1.0 : 0.4)
        .animation(.easeInOut(duration: 0.3), value: vm.isInPrayerWindow)
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
