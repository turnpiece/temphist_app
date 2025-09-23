import 'package:flutter/material.dart';

/// Enable verbose logging in production builds
/// Usage: flutter build ios --dart-define=VERBOSE_LOGS=true
/// Or set environment variable: VERBOSE_LOGS=true
const bool verboseLogs = bool.fromEnvironment('VERBOSE_LOGS', defaultValue: false);

/// App color constants
const kBackgroundColourDark = Color(0xFF242456);
const kBackgroundColourLight = Color(0xFF343499);
const kAccentColour = Color(0xFFFF6B6B);
const kTextPrimaryColour = Color(0xFFECECEC);
const kSummaryColour = Color(0xFF51CF66);
const kAverageColour = Color(0xFF4DABF7);
const kTrendColour = Color(0xFFAAAA00);
const kTrendLineColour = kTrendColour;
const kBarOtherYearColour = kAccentColour;
const kBarCurrentYearColour = kSummaryColour;

// Additional color constants for UI components
const kBackgroundColour = kBackgroundColourDark;
const kTextColour = kTextPrimaryColour;
const kCardColour = Color(0xFF2A2A5A);

// Temperature conversion constants
const kKelvinOffset = 273.15; // Celsius to Kelvin conversion

const kAxisLabelColour = Color(0xFFECECEC);
const kAxisGridColour = kAxisLabelColour;
const kGreyLabelColour = Color(0xFFB0B0B0);

// App constants
const String kAppTitle = 'TempHist'; // Application title

/// Additional build-time constants can be added here as needed
/// Examples:
/// const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);
/// const String apiEndpoint = String.fromEnvironment('API_ENDPOINT', defaultValue: 'https://api.example.com');
