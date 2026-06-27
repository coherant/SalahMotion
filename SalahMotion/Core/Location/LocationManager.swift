import CoreLocation

@Observable
final class LocationManager: NSObject {

    private(set) var cityName: String = "Locating…"
    private(set) var coordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var hasFetched = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        guard !hasFetched else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            fetchOnce()
        case .denied, .restricted:
            cityName = "Location off"
        @unknown default:
            break
        }
    }

    private func fetchOnce() {
        guard !hasFetched else { return }
        hasFetched = true
        manager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            let placemark = placemarks?.first
            let city = placemark?.locality
                    ?? placemark?.administrativeArea
                    ?? "Unknown"
            let tz = placemark?.timeZone
            DispatchQueue.main.async {
                self?.cityName = city
                if let tz { PrayerTimesEngine.shared.setTimeZone(tz) }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            fetchOnce()
        case .denied, .restricted:
            cityName = "Location off"
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            self?.coordinate = location.coordinate
            PrayerTimesEngine.shared.setCoordinate(location.coordinate)
        }
        reverseGeocode(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        cityName = "Melbourne"
    }
}
