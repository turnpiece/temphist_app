// Pure helper functions for temperature unit conversion and formatting.
//
// All internal/cached data stays in Celsius.  These functions convert at
// the display layer only.

/// Convert a Celsius value to Fahrenheit.
double celsiusToFahrenheit(double celsius) => celsius * 9 / 5 + 32;

/// Format a temperature for display.
///
/// When [isFahrenheit] is true and [convert] is true (the default), the value
/// is assumed to be in Celsius and is converted to Fahrenheit.  When [convert]
/// is false the value is already in the target unit and only formatting
/// (unit label and decimal places) is applied.
String formatTemperature(
  double value, {
  required bool isFahrenheit,
  bool convert = true,
}) {
  final display = (isFahrenheit && convert) ? celsiusToFahrenheit(value) : value;
  final unit = isFahrenheit ? '°F' : '°C';
  final decimals = isFahrenheit ? 0 : 1;
  return '${display.toStringAsFixed(decimals)}$unit';
}

/// Format a trend slope for display.
///
/// When [isFahrenheit] is true and [convert] is true (the default), the slope
/// is assumed to be in °C/decade and is scaled by ×1.8 (no +32 offset, since
/// slope is a rate).  When [convert] is false the value is already in the
/// target unit.
String formatTrendSlope(
  double slopePerDecade, {
  required bool isFahrenheit,
  bool convert = true,
}) {
  final value = (isFahrenheit && convert) ? slopePerDecade * 9 / 5 : slopePerDecade;
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
