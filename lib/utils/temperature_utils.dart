// Pure helper functions for temperature unit conversion and formatting.
//
// All internal/cached data stays in Celsius.  These functions convert at
// the display layer only.

/// Convert a Celsius value to Fahrenheit.
double celsiusToFahrenheit(double celsius) => celsius * 9 / 5 + 32;

/// Format a temperature (stored in Celsius) for display.
///
/// Returns e.g. `"14.2°C"` or `"57.6°F"` depending on [isFahrenheit].
String formatTemperature(double celsius, {required bool isFahrenheit}) {
  final value = isFahrenheit ? celsiusToFahrenheit(celsius) : celsius;
  final unit = isFahrenheit ? '°F' : '°C';
  return '${value.toStringAsFixed(1)}$unit';
}

/// Format a trend slope (°C per decade) for display.
///
/// The slope is a *rate*, so only the scaling factor (×1.8) applies — no +32
/// offset.  Returns e.g. `"Trend: Rising at 0.3°F/decade"`.
String formatTrendSlope(double slopePerDecade, {required bool isFahrenheit}) {
  final value = isFahrenheit ? slopePerDecade * 9 / 5 : slopePerDecade;
  final unit = isFahrenheit ? '°F/decade' : '°C/decade';
  if (value.abs() < 0.05) {
    return 'Trend: Steady at ${value.abs().toStringAsFixed(1)}$unit';
  }
  return value > 0
      ? 'Trend: Rising at ${value.abs().toStringAsFixed(1)}$unit'
      : 'Trend: Falling at ${value.abs().toStringAsFixed(1)}$unit';
}

/// Return the unit suffix string: `"°F"` or `"°C"`.
String temperatureUnitLabel({required bool isFahrenheit}) =>
    isFahrenheit ? '°F' : '°C';
