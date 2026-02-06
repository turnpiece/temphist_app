import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/period_temperature_data.dart';
import '../services/temperature_service.dart';
import '../utils/debug_utils.dart';
import 'temperature_bar_chart.dart';

// Colour / layout constants matching main.dart
const _kBackgroundColour = Color(0xFF242456);
const _kAccentColour = Color(0xFFFF6B6B);
const _kTextPrimaryColour = Color(0xFFECECEC);
const _kSummaryColour = Color(0xFF51CF66);
const _kAverageColour = Color(0xFF4DABF7);
const _kTrendColour = Color(0xFFAAAA00);
const _kGreyLabelColour = Color(0xFFB0B0B0);
const double _kFontSizeBody = 17.0;
const double _kScreenPadding = 12.0;
const double _kContentHorizontalMargin = 8.0;
const double _kSectionBottomPadding = 22.0;
const double _kContentVerticalPadding = 32.0;

/// A reusable page that fetches and displays period temperature data
/// (weekly, monthly, or yearly) using the v1 records API.
class PeriodPage extends StatefulWidget {
  /// The API period key: 'week', 'month', or 'year'.
  final String periodKey;

  /// Human-readable label, e.g. "Week", "Month", "Year".
  final String periodLabel;

  /// The full location string for API calls (e.g. "London, Greater London, UK").
  final String location;

  /// Short location for display (e.g. "London, UK"). Falls back to [location].
  final String? displayLocation;

  /// Callback invoked when pull-to-refresh is triggered.
  final Future<void> Function()? onRefresh;

  const PeriodPage({
    super.key,
    required this.periodKey,
    required this.periodLabel,
    required this.location,
    this.displayLocation,
    this.onRefresh,
  });

  @override
  State<PeriodPage> createState() => PeriodPageState();
}

class PeriodPageState extends State<PeriodPage>
    with AutomaticKeepAliveClientMixin {
  PeriodTemperatureData? _data;
  bool _isLoading = false;
  String? _error;
  String _loadingMessage = '';

  // Cache key to avoid re-fetching when swiping back
  String _lastFetchKey = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(PeriodPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      // Location changed — re-fetch
      _lastFetchKey = '';
      _loadIfNeeded();
    }
  }

  String get _identifier {
    final now = DateTime.now();
    final useYesterday = now.hour < 3;
    final dateToUse = useYesterday ? now.subtract(const Duration(days: 1)) : now;

    // Handle leap day
    if (dateToUse.month == 2 && dateToUse.day == 29) {
      return '02-28';
    }
    return DateFormat('MM-dd').format(dateToUse);
  }

  String get _fetchKey => '${widget.periodKey}|${widget.location}|$_identifier';

  void _loadIfNeeded() {
    if (widget.location.isEmpty) return;
    if (_fetchKey == _lastFetchKey && _data != null) return;
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _loadingMessage = 'Loading ${widget.periodLabel.toLowerCase()} temperature data...';
    });

    try {
      final service = TemperatureService();
      final data = await service.fetchPeriodData(
        widget.periodKey,
        widget.location,
        _identifier,
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _loadingMessage = status.isPending
                  ? 'Processing ${widget.periodLabel.toLowerCase()} data...'
                  : 'Almost there...';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
          _lastFetchKey = _fetchKey;
        });
      }
    } on RateLimitException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Rate limit exceeded. Please wait a moment and try again.';
        });
      }
    } catch (e) {
      DebugUtils.logLazy(() => 'PeriodPage error (${widget.periodKey}): $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load ${widget.periodLabel.toLowerCase()} data. '
              'Please check your connection and try again.';
        });
      }
    }
  }

  /// Called externally (e.g. on location change) to force a reload.
  void reload() {
    _lastFetchKey = '';
    _data = null;
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    if (widget.location.isEmpty) {
      return const Center(
        child: Text(
          'Determining location...',
          style: TextStyle(color: _kGreyLabelColour, fontSize: _kFontSizeBody),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _lastFetchKey = '';
        await _fetchData();
        if (widget.onRefresh != null) await widget.onRefresh!();
      },
      color: _kAccentColour,
      backgroundColor: _kBackgroundColour,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    double leftPadding;
    double rightPadding;

    if (isTablet) {
      final titleTextStartPosition = 40 + 6;
      leftPadding = _kScreenPadding + _kContentHorizontalMargin + titleTextStartPosition;
      rightPadding = leftPadding;
    } else {
      leftPadding = _kScreenPadding + _kContentHorizontalMargin;
      rightPadding = _kScreenPadding + _kContentHorizontalMargin;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: leftPadding,
        right: rightPadding,
        bottom: MediaQuery.of(context).padding.bottom + _kContentVerticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading state
          if (_isLoading && _data == null) _buildLoadingState(),

          // Error state
          if (_error != null) _buildErrorState(),

          // Data loaded
          if (_data != null) ..._buildDataContent(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _kGreyLabelColour,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _loadingMessage,
            style: const TextStyle(color: _kGreyLabelColour, fontSize: _kFontSizeBody),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: _kAccentColour, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(color: _kAccentColour, fontSize: _kFontSizeBody - 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _kAccentColour.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: _kAccentColour, fontSize: _kFontSizeBody - 2, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataContent() {
    final data = _data!;
    final currentYear = DateTime.now().year;

    // Convert API values to chart data
    final chartData = data.values.map((v) {
      return TemperatureChartData(
        year: v.year.toString(),
        temperature: v.temperature,
        isCurrentYear: v.year == currentYear,
        hasData: true,
      );
    }).toList();

    // Build display date string
    final displayDate = _buildDisplayDate();

    return [
      // Date
      Padding(
        padding: const EdgeInsets.only(bottom: _kSectionBottomPadding),
        child: Text(
          displayDate,
          style: const TextStyle(color: _kTextPrimaryColour, fontSize: _kFontSizeBody),
        ),
      ),
      // Location
      Padding(
        padding: const EdgeInsets.only(bottom: _kSectionBottomPadding),
        child: Text(
          widget.displayLocation ?? widget.location,
          style: const TextStyle(color: _kTextPrimaryColour, fontSize: _kFontSizeBody),
        ),
      ),
      // Summary
      if (data.summary.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: _kSectionBottomPadding),
          child: Text(
            data.summary,
            style: const TextStyle(color: _kSummaryColour, fontSize: _kFontSizeBody),
          ),
        ),
      // Chart
      TemperatureBarChart(
        chartData: chartData,
        averageTemperature: data.average.mean,
        trendSlope: data.trend.slope,
        isLoading: false,
        height: 800,
      ),
      const SizedBox(height: _kSectionBottomPadding),
      // Average text
      Padding(
        padding: const EdgeInsets.only(bottom: _kSectionBottomPadding),
        child: Text(
          'Average: ${data.average.mean.toStringAsFixed(1)}°C',
          style: const TextStyle(color: _kAverageColour, fontSize: _kFontSizeBody),
        ),
      ),
      // Trend text
      Padding(
        padding: const EdgeInsets.only(bottom: _kSectionBottomPadding),
        child: Text(
          _formatTrend(data.trend.slope),
          style: const TextStyle(color: _kTrendColour, fontSize: _kFontSizeBody),
        ),
      ),
      // Completeness notice
      if (data.metadata != null && data.metadata!.completeness < 100)
        Padding(
          padding: const EdgeInsets.only(bottom: _kSectionBottomPadding),
          child: Text(
            'Data completeness: ${data.metadata!.completeness.toStringAsFixed(0)}%',
            style: const TextStyle(color: _kGreyLabelColour, fontSize: _kFontSizeBody - 2),
          ),
        ),
    ];
  }

  String _buildDisplayDate() {
    final now = DateTime.now();
    final useYesterday = now.hour < 3;
    final dateToUse = useYesterday ? now.subtract(const Duration(days: 1)) : now;

    switch (widget.periodKey) {
      case 'week':
        final weekStart = dateToUse.subtract(Duration(days: dateToUse.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Week ending ${_formatDate(weekEnd)}';
      case 'month':
        return DateFormat('MMMM').format(dateToUse);
      case 'year':
        return dateToUse.year.toString();
      default:
        return _formatDate(dateToUse);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
        case 2:
          suffix = 'nd';
        case 3:
          suffix = 'rd';
        default:
          suffix = 'th';
      }
    }
    final month = DateFormat('MMMM').format(date);
    return '$day$suffix $month';
  }

  String _formatTrend(double slope) {
    if (slope.abs() < 0.05) {
      return 'Trend: Steady at ${slope.abs().toStringAsFixed(1)}°C/decade';
    }
    return slope > 0
        ? 'Trend: Rising at ${slope.abs().toStringAsFixed(1)}°C/decade'
        : 'Trend: Falling at ${slope.abs().toStringAsFixed(1)}°C/decade';
  }
}
