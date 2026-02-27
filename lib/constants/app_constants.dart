import 'package:flutter/material.dart';

/// App color constants
/// These colors define the visual theme of the TempHist application
const kBackgroundColour = Color(0xFF242456);
const kBackgroundColourDark = Color(0xFF343499);
const kAccentColour = Color(0xFFFF6B6B);
const kTextPrimaryColour = Color(0xFFECECEC);
const kSummaryColour = Color(0xFF51CF66);
const kAverageColour = Color(0xFF4DABF7);
const kTrendColour = Color(0xFFAAAA00);
const kTrendLineColour = kTrendColour;
const kBarOtherYearColour = kAccentColour;
const kBarCurrentYearColour = kSummaryColour;
const kAxisLabelColour = Color(0xFFECECEC);
const kAxisGridColour = kAxisLabelColour;
const kGreyLabelColour = Color(0xFFB0B0B0);

/// Layout constants for easy adjustment
/// These constants control the spacing and padding throughout the app's UI

// Base padding from screen edges - affects all content
const double kScreenPadding = 12.0;

// Title/logo section spacing
const double kTitleRowIconRightPadding = 6.0;
const double kTitleRowBottomPadding = 16.0;

// Main content area margins
const double kContentHorizontalMargin = 8.0;
const double kContentVerticalPadding = 32.0;

// Chart-specific spacing
const double kChartHorizontalMargin = 0.0;
const double kChartInnerPadding = 0.0;
const double kChartRightMargin = 20.0;

// Section spacing - controls gaps between UI sections
const double kSectionBottomPadding = 14.0;
const double kSectionTopPadding = 14.0;

/// App constants
const String kAppTitle = 'TempHist';

/// Font size constants - control text sizing throughout the app
const double kFontSizeTitle = 26.0;
const double kFontSizeLocation = 18.0; // Slightly larger for location
const double kFontSizeBody = 17.0; // Standard body text, summary, average, trend
const double kFontSizeAxisLabel = 17.0; // Same as body for consistency
const double kIconSize = 17.0;
const double kSummaryFontSize = kFontSizeBody; // Changed from -2 for consistency
const double kSummaryLineHeight = 1.2;
const double kSummaryMinLines = 4;

/// Enable verbose logging in production builds via dart-define.
/// Usage: flutter build ios --dart-define=VERBOSE_LOGS=true
const bool verboseLogs = bool.fromEnvironment('VERBOSE_LOGS', defaultValue: false);

/// Time constants
const int kUseYesterdayHourThreshold = 3;
const int kAverageTrendDisplayDelaySeconds = 35;
const int kApiTimeoutSeconds = 35;

/// Default location constant
const String kDefaultLocation = 'London, UK';
