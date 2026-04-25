import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Write iOS system temperature unit preference to UserDefaults before the
    // Flutter engine starts so Dart can read it via shared_preferences.
    // MeasurementFormatter respects the iOS 16+ explicit Temperature setting;
    // on iOS 15 it falls back to the region default.
    // iOS 16+ stores the explicit temperature unit preference as "AppleTemperatureUnit"
    // in NSUserDefaults ("Celsius" or "Fahrenheit"), separate from the regional locale.
    // MeasurementFormatter uses the regional default and ignores this override.
    let explicitUnit = UserDefaults.standard.string(forKey: "AppleTemperatureUnit")
    let isFahrenheit: Bool
    if let unit = explicitUnit {
      isFahrenheit = (unit == "Fahrenheit")
    } else {
      // Not explicitly set — fall back to regional locale heuristic.
      isFahrenheit = Locale.current.regionCode == "US"
    }
    // shared_preferences stores keys with a "flutter." prefix in NSUserDefaults.
    UserDefaults.standard.set(isFahrenheit, forKey: "flutter.ios_system_temperature_fahrenheit")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
