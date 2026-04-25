import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Register platform channel after super so that window/rootViewController are set up.
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "com.turnpiece.temphist/system_prefs",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getTemperatureUnitIsFahrenheit" {
        let formatter = MeasurementFormatter()
        let measurement = Measurement(value: 0, unit: UnitTemperature.celsius)
        let formatted = formatter.string(from: measurement)
        // MeasurementFormatter converts to the system-preferred unit.
        // On iOS 16+ this respects the explicit Temperature setting in Language & Region;
        // on iOS 15 it falls back to the region default.
        result(!formatted.contains("°C") && !formatted.contains("C"))
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    return launched
  }
}
