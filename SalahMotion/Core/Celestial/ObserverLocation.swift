import Foundation

// MARK: - ObserverLocation
//
// A lightweight observer position for the celestial domain. Deliberately NOT the
// Adhan `Coordinates` type — keeping the domain's public surface free of the
// vendored library means providers can be swapped and tested in isolation, and
// the model ports to watchOS without dragging prayer-time types along.

struct ObserverLocation: Equatable {
    let latitude: Double
    let longitude: Double

    /// Drives the Moon's bright-limb mirroring: in the Southern Hemisphere the
    /// lit side is flipped relative to the Northern convention. The *view* applies
    /// the mirror; the domain just reports which hemisphere we're in.
    var isNorthernHemisphere: Bool { latitude >= 0 }
}
