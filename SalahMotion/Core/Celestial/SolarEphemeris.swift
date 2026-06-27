import Foundation

// MARK: - SolarEphemeris
//
// The real Sun, computed by the vendored Adhan astronomy (the same Meeus engine
// that produces the app's prayer times) — so it adds zero new astronomy and
// carries zero drift risk. Translates Adhan's rise/transit/set into the domain's
// daily-arc phase via `DailyArc`.

struct SolarEphemeris: CelestialEphemeris {

    func sky(at date: Date, location: ObserverLocation) -> SkyState {
        let coordinates = Coordinates(latitude: location.latitude, longitude: location.longitude)

        guard let today = events(on: date, coordinates: coordinates) else {
            // Polar day/night (no rise/set): treat as below the horizon.
            return SkyState(dayPhase: 0.75, isAboveHorizon: false, moonPhase: nil)
        }

        let calendar = Calendar.gregorianUTC
        let yesterday = calendar.date(byAdding: .day, value: -1, to: date)
            .flatMap { events(on: $0, coordinates: coordinates) }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)
            .flatMap { events(on: $0, coordinates: coordinates) }

        let phase = DailyArc.phase(
            now: date,
            previousSet: yesterday?.set,
            rise: today.rise,
            transit: today.transit,
            set: today.set,
            nextRise: tomorrow?.rise
        )
        let above = date >= today.rise && date < today.set
        return SkyState(dayPhase: phase, isAboveHorizon: above, moonPhase: nil)
    }

    // MARK: Adhan bridge

    private func events(on date: Date,
                        coordinates: Coordinates) -> (rise: Date, transit: Date, set: Date)? {
        let calendar = Calendar.gregorianUTC
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let solar = SolarTime(date: components, coordinates: coordinates),
              let rise = calendar.date(from: solar.sunrise),
              let transit = calendar.date(from: solar.transit),
              let set = calendar.date(from: solar.sunset) else {
            return nil
        }
        return (rise, transit, set)
    }
}
