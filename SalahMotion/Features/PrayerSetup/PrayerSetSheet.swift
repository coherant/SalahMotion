import SwiftUI

struct PrayerSetSheet: View {
    @Binding var isPresented: Bool
    @Environment(UserPreferences.self) private var prefs

    private var salat:   SalatType   { prefs.salatType }
    private var unitIds: Set<String> { prefs.selectedUnitIds }

    private var accent: Color { salat.prayerTime.setupAccent }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Grabber
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

            // Header
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Prayer set")
                        .font(Typography.eyebrow)
                        .tracking(2.5)
                        .textCase(.uppercase)
                        .foregroundStyle(DesignTokens.faint)
                    Text("Compose the session")
                        .font(Typography.display(23, weight: .medium))
                        .foregroundStyle(DesignTokens.ink)
                }
                Spacer()
                Button("Done") { isPresented = false }
                    .font(Typography.ui(14, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 18)

            // Prayer chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SalatType.allCases) { s in
                        Button {
                            prefs.salatType = s
                            prefs.selectedUnitIds = []
                        } label: {
                            Text(s.displayName)
                                .font(Typography.ui(13, weight: .semibold))
                                .foregroundStyle(s == salat ? DesignTokens.darkOnAccent : DesignTokens.muted)
                                .padding(.horizontal, 15).padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(s == salat
                                              ? accent
                                              : Color.white.opacity(0.05))
                                        .overlay(
                                            Capsule().strokeBorder(
                                                s == salat ? Color.clear : Color.white.opacity(0.08),
                                                lineWidth: 1
                                            )
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)
            }
            .padding(.bottom, 18)

            // Unit rows
            VStack(spacing: 8) {
                ForEach(salat.units) { unit in
                    unitRow(unit)
                }
            }
            .padding(.horizontal, 22)

            Spacer().frame(height: 24)
        }
        .background(DesignTokens.sheetGradient(accent: accent))
    }

    private func unitRow(_ unit: PrayerUnit) -> some View {
        let checked = unit.isObligatory || unitIds.contains(unit.id)

        return Button {
            if !unit.isObligatory {
                var ids = prefs.selectedUnitIds
                if ids.contains(unit.id) { ids.remove(unit.id) } else { ids.insert(unit.id) }
                prefs.selectedUnitIds = ids
            }
        } label: {
            HStack(spacing: 13) {
                // Count badge
                Text("×\(unit.rakats)")
                    .font(Typography.display(18, weight: .semibold))
                    .foregroundStyle(DesignTokens.ink)
                    .frame(width: 34, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(checked ? accent.opacity(0.16) : Color.white.opacity(0.06))
                    )

                // Name + tag
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(unit.displayName)
                            .font(Typography.ui(15, weight: .semibold))
                            .foregroundStyle(DesignTokens.ink)
                        Text(unit.arabicName)
                            .font(Typography.arabic(14))
                            .foregroundStyle(checked ? accent : DesignTokens.faint)
                    }
                    Text(unit.tagText)
                        .font(Typography.ui(11))
                        .tracking(0.3)
                        .foregroundStyle(DesignTokens.faint)
                }

                Spacer()

                // Toggle
                ZStack {
                    Circle()
                        .fill(checked ? accent : Color.clear)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle().strokeBorder(
                                checked ? Color.clear : Color.white.opacity(0.2),
                                lineWidth: 1.5
                            )
                        )
                        .shadow(color: checked ? accent.opacity(0.6) : .clear, radius: 5)
                    if checked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DesignTokens.darkOnAccent)
                    }
                }
                .opacity(unit.isObligatory ? 0.8 : 1)
            }
            .padding(.horizontal, 13).padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(checked ? accent.opacity(0.10) : Color.white.opacity(0.035))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                checked ? accent.opacity(0.32) : Color.white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(unit.isObligatory)
    }
}

#Preview {
    PrayerSetSheetPreview()
}

private struct PrayerSetSheetPreview: View {
    @State private var shown   = true
    @State private var salat   = SalatType.maghrib
    @State private var unitIds = Set<String>()
    var body: some View {
        Color.black.ignoresSafeArea()
            .sheet(isPresented: $shown) {
                PrayerSetSheet(isPresented: $shown)
                    .presentationBackground(DesignTokens.sheetGradient(accent: Color(hex: "#9a86c7")))
            }
    }
}
