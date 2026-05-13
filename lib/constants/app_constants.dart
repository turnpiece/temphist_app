import 'package:flutter/material.dart';

/// App color constants
/// These colors define the visual theme of the TempHist application
const kBackgroundColour = Color(0xFF242456);
const kBackgroundColourDark = Color(0xFF343499);
const kTextPrimaryColour = Color(0xFFECECEC);
const kSummaryColour = Color(0xFF51CF66);
const kButtonColour = kSummaryColour;
const kAccentColour = kButtonColour;
const kHeadingColour = Color(0xFFD0D4DE);
const kAverageColour = kHeadingColour;
const kTrendColour = Color(0xFFC8C400);
const kTrendLineColour = kTrendColour;
const kBarOtherYearColour = Color(0xFFFF6B6B);
const kBarCurrentYearColour = kSummaryColour;
const kBarWarmColour = Color(0xFFFF3B30);
const kBarCoolColour = Color(0xFF3B82F6);
const kBarNeutralColour = Color(0xFF8E8E93);
const kBarCurrentYearBorderColour = Color(0xFF00FF7F);
const kLocationRecentColour = Color(0xFF6DC88A);
const kLocationPopularColour = Color(0xFFD0D4DE);
const kAxisLabelColour = Color(0xFFECECEC);
const kAxisGridColour = kAxisLabelColour;
const kGreyLabelColour = Color(0xFFB0B0B0);
const kSegmentedControlBackgroundColour = Color(0x1FECECEC);
const kSegmentedControlSelectedBackgroundColour = Color(0x2EECECEC);
const kSegmentedControlSelectedTextColour = kTextPrimaryColour;
const kSegmentedControlUnselectedTextColour = kHeadingColour;
const kChartAxisFontFamilyFallback = [
  'SF Mono',
  'Menlo',
  'Roboto Mono',
  'monospace'
];

/// Layout constants for easy adjustment
/// These constants control the spacing and padding throughout the app's UI

// Base padding from screen edges - affects all content
const double kScreenPadding = 12.0;

// Title/logo section spacing
const double kTitleRowIconRightPadding = 6.0;
const double kTitleRowBottomPadding = 16.0;

// Main content area margins
const double kContentHorizontalMargin = 8.0;
const double kContentVerticalPadding = 20.0;

// Chart-specific spacing
const double kChartHorizontalMargin = 0.0;
const double kChartInnerPadding = 0.0;
const double kChartRightMargin = 20.0;

// Section spacing - controls gaps between UI sections
const double kSectionBottomPadding = 14.0;
const double kSectionTopPadding = 14.0;

/// App constants
const String kAppTitle = 'TempHist';

const String _kApiBaseUrlDefine = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

String _normalizeApiOrigin(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'https://api.temphist.com';
  return trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}

/// API origin (no trailing slash).
///
/// Set at compile/run time with `--dart-define=API_BASE_URL=...` (e.g. dev API).
/// If unset or blank, uses `https://api.temphist.com`.
///
/// Example: `flutter run --dart-define=API_BASE_URL=https://devapi.temphist.com`
///
/// Override in tests via [TemperatureService] constructor.
final String kApiBaseUrl = _normalizeApiOrigin(_kApiBaseUrlDefine);

/// Public HTTPS origin for snapshot share pages (`/s/:id`). No trailing slash.
///
/// The API may live on another host ([kApiBaseUrl]); share links must still
/// point here so Messages and other apps fetch HTML with Open Graph previews.
const String kSharePageOrigin = 'https://temphist.com';

/// Rewrites a share URL from the API (any host) to [kSharePageOrigin] when it
/// contains `/s/:id`, so OS share sheets load public Open Graph HTML.
String canonicalShareSnapshotUrl(String apiReturnedUrl) {
  final trimmed = apiReturnedUrl.trim();
  final id = RegExp(r'/s/([^/?#]+)').firstMatch(trimmed)?.group(1);
  if (id != null && id.isNotEmpty) {
    return '$kSharePageOrigin/s/$id';
  }
  return trimmed;
}

/// Maps app period keys (`daily`, `week`, `month`, `year`) to v1 records API path segments.
String kApiRecordsPeriodSegment(String period) {
  switch (period) {
    case 'week':
      return 'weekly';
    case 'month':
      return 'monthly';
    case 'year':
      return 'yearly';
    case 'daily':
    default:
      return 'daily';
  }
}

/// Font size constants - control text sizing throughout the app
const double kFontSizeTitle = 26.0;
const double kFontSizeLocation = 21.0;
const double kFontSizeBody =
    17.0; // Standard body text, summary, average, trend
const double kFontSizeAxisLabel = 16.0; // Slightly smaller for chart labels
const double kIconSize = 17.0;
const double kSummaryFontSize =
    kFontSizeBody; // Changed from -2 for consistency
const double kSummaryLineHeight = 1.2;
const double kSummaryMinLines = 4;
const double kSummaryMinLinesTablet = 3;
const double kSmallPhoneBreakpointWidth = 380.0;
const double kSummaryBubbleVerticalPadding = 12.0;
const double kBubbleBorderRadius = 10.0;
const Color kSummaryBubbleColour = kSummaryColour;
const Color kSummaryTextColour = Colors.white;

const Color kErrorColour = Color(0xFFFFAA33);
const Color kStatsBubbleColour = Color(0xFF607090);
const Color kStdDevColour = Color(0xFF8AAFD0);
const double kStatsFontSize = 15.0;

/// Enable verbose logging in production builds via dart-define.
/// Usage: flutter build ios --dart-define=VERBOSE_LOGS=true
const bool verboseLogs =
    bool.fromEnvironment('VERBOSE_LOGS', defaultValue: false);

/// Time constants
const int kUseYesterdayHourThreshold = 3;
const int kAverageTrendDisplayDelaySeconds = 35;
const int kApiTimeoutSeconds = 35;
const int kApiLongTimeoutSeconds = 60;
const int kJobPollTimeoutSeconds = 15;
const int kFirebaseAuthTimeoutSeconds = 15;
const int kLocationTimeoutSeconds = 10;
const int kConnectivityTestTimeoutSeconds = 5;

/// Chart constants
const double kTabletBreakpointWidth = 700.0;
const double kTabletMaxContentWidth = 600.0;
const double kChartHeight = 800.0;
const int kChartStartYear = 1975;
// Visual Crossing currently limits historical API coverage to a 50-year window.
// Keep this as a single source of truth so expanding coverage (e.g. 100 years)
// only requires updating one constant.
const int kHistoricalDataWindowYears = 50;

/// Location constants
const int kLocationDistanceFilterMeters = 500;
const int kLocationSignificantChangeMeters = 1000;
const int kMaxChartDataRetries = 3;

/// Default location constant
const String kDefaultLocation = 'London, UK';

/// Privacy policy URL
const String kPrivacyPolicyUrl = 'https://temphist.com/privacy/app';
