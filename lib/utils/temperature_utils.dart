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
///
/// Both units use 1 decimal place (e.g. "0.3°C/decade", "0.8°F/decade").
String formatTrendSlope(
  double slopePerDecade, {
  required bool isFahrenheit,
  bool convert = true,
}) {
  final value = (isFahrenheit && convert) ? slopePerDecade * 9 / 5 : slopePerDecade;
  final unit = isFahrenheit ? '°F/decade' : '°C/decade';
  final formatted = value.abs().toStringAsFixed(2);
  if (value.abs() < 0.05) {
    return 'Trend: Steady at $formatted$unit';
  }
  return value > 0
      ? 'Trend: Rising at $formatted$unit'
      : 'Trend: Falling at $formatted$unit';
}

/// Returns the trend value phrase without a "Trend: " prefix, optionally
/// including an error margin: e.g. "Rising at 1.1±0.1°C/decade".
String formatTrendValue(
  double slopePerDecade, {
  double? slopeError,
  required bool isFahrenheit,
  bool convert = true,
}) {
  final value = (isFahrenheit && convert) ? slopePerDecade * 9 / 5 : slopePerDecade;
  final errorValue =
      (slopeError != null && isFahrenheit && convert) ? slopeError * 9 / 5 : slopeError;
  final unit = isFahrenheit ? '°F/decade' : '°C/decade';
  final formatted = value.abs().toStringAsFixed(2);
  final errorStr = errorValue != null ? ' ± ${errorValue.toStringAsFixed(2)}' : '';
  if (value.abs() < 0.05) return 'Steady at $formatted$errorStr$unit';
  return value > 0
      ? 'Rising at $formatted$errorStr$unit'
      : 'Falling at $formatted$errorStr$unit';
}

/// Return the unit suffix string: `"°F"` or `"°C"`.
String temperatureUnitLabel({required bool isFahrenheit}) =>
    isFahrenheit ? '°F' : '°C';

/// Return the MM-dd identifier for [date], applying the Feb 29 → Feb 28
/// fallback used throughout the app (the API has no Feb 29 data).
String dateIdentifier(DateTime date) {
  if (date.month == 2 && date.day == 29) return '02-28';
  return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
