import Foundation

struct UserCalibrationProfile: Codable {
    var rukuPitchLow:     Double
    var rukuPitchHigh:    Double
    var uprightPitchLow:  Double
    var uprightPitchHigh: Double
    var sujoodRollRadius: Double  // max angularDistance from 180°
    var tasleemYawOffset: Double  // min yaw delta from baseline to confirm head turn

    private static let defaultsKey = "userCalibrationProfile"

    static func load() -> UserCalibrationProfile? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let profile = try? JSONDecoder().decode(UserCalibrationProfile.self, from: data)
        else { return nil }
        return profile
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
