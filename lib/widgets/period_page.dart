import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/period_temperature_data.dart';
import '../services/temperature_service.dart';
import '../services/period_cache_service.dart';
import '../utils/debug_utils.dart';
import '../utils/temperature_utils.dart';
import 'completeness_section.dart';
import 'temperature_bar_chart.dart';

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

  /// GPS coordinates used for Hive cache key. Optional — cache is skipped
  /// if not provided (e.g. when using default location).
  final double? latitude;
  final double? longitude;

  /// Whether this widget wraps its own scroll/refresh UI.
  final bool useInternalScroll;

  /// Whether to display temperatures in Fahrenheit.
  final bool isFahrenheit;

  const PeriodPage({
    super.key,
    required this.periodKey,
    required this.periodLabel,
    required this.location,
    this.displayLocation,
    this.latitude,
    this.longitude,
    this.onRefresh,
    this.useInternalScroll = true,
    this.isFahrenheit = false,
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

  // Generation counter — incremented whenever location/unit changes so that
  // any in-flight fetch from the previous configuration is discarded.
  int _fetchGeneration = 0;

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
    if (oldWidget.location != widget.location ||
        oldWidget.isFahrenheit != widget.isFahrenheit) {
      // Location or unit changed — increment generation so any in-flight fetch
      // is discarded, clear stale data immediately, then re-fetch.
      _fetchGeneration++;
      _lastFetchKey = '';
      _data = null;
      _isLoading = false;
      _loadIfNeeded();
    }
  }

  String get _identifier {
    final now = DateTime.now();
    final useYesterday = now.hour < kUseYesterdayHourThreshold;
    final dateToUse = useYesterday ? now.subtract(const Duration(days: 1)) : now;
    return dateIdentifier(dateToUse);
  }

  String get _unitGroup => widget.isFahrenheit ? 'fahrenheit' : 'celsius';

  String get _fetchKey =>
      '${widget.periodKey}|${widget.location}|$_identifier|$_unitGroup';

  void _loadIfNeeded() {
    if (widget.location.isEmpty) return;
    if (_fetchKey == _lastFetchKey && _data != null) return;
    _fetchData();
  }

  Future<void> _fetchData({bool bypassCache = false}) async {
    if (_isLoading) return;

    final generation = _fetchGeneration;

    setState(() {
      _isLoading = true;
      _error = null;
      _loadingMessage = 'Loading ${widget.periodLabel.toLowerCase()} temperature data...';
    });

    try {
      final lat = widget.latitude;
      final lon = widget.longitude;

      // Cache-first: serve from Hive when available, fall through on miss.
      // bypassCache is set when retrying to ensure fresh data from the API.
      final unitGroup = widget.isFahrenheit ? 'fahrenheit' : null;
      if (bypassCache) {
        // Evict only this period's entry from the in-memory service cache so
        // the retry goes to the network without disturbing other periods.
        TemperatureService.evictCacheEntry(
          widget.periodKey,
          widget.location,
          _identifier,
          unitGroup: unitGroup,
        );
      }
      PeriodTemperatureData? data;
      if (!bypassCache && lat != null && lon != null) {
        data = await PeriodCacheService.get(
          widget.periodKey, lat, lon, _identifier,
          unitGroup: unitGroup,
        );
        if (data != null) {
          DebugUtils.logLazy(
            () => 'PeriodPage(${widget.periodKey}): served from Hive cache',
          );
        }
      }

      if (data == null) {
        final service = TemperatureService();
        data = await service.fetchPeriodData(
          widget.periodKey,
          widget.location,
          _identifier,
          unitGroup: unitGroup,
          onProgress: (status) {
            if (mounted && _fetchGeneration == generation) {
              setState(() {
                _loadingMessage = status.isPending
                    ? 'Processing ${widget.periodLabel.toLowerCase()} data...'
                    : 'Almost there...';
              });
            }
          },
        );

        if (lat != null && lon != null) {
          await PeriodCacheService.put(
            widget.periodKey, lat, lon, _identifier, data,
            unitGroup: unitGroup,
          );
        }
      }

      if (mounted && _fetchGeneration == generation) {
        setState(() {
          _data = data;
          _isLoading = false;
          _lastFetchKey = _fetchKey;
        });
      }
    } on RateLimitException {
      if (mounted && _fetchGeneration == generation) {
        setState(() {
          _isLoading = false;
          _error = 'Rate limit exceeded. Please wait a moment and try again.';
        });
      }
    } catch (e) {
      DebugUtils.logLazy(() => 'PeriodPage error (${widget.periodKey}): $e');
      if (mounted && _fetchGeneration == generation) {
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

  /// Public refresh hook for external RefreshIndicator.
  Future<void> refresh() async {
    _lastFetchKey = '';
    await _fetchData(bypassCache: true);
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    if (widget.location.isEmpty) {
      return const Center(
        child: Text(
          'Determining location...',
          style: TextStyle(color: kGreyLabelColour, fontSize: kFontSizeBody),
        ),
      );
    }

    if (!widget.useInternalScroll) {
      return _buildContent(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        _lastFetchKey = '';
        await _fetchData();
        if (widget.onRefresh != null) await widget.onRefresh!();
      },
      color: kAccentColour,
      backgroundColor: kBackgroundColour,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final leftPadding = kScreenPadding + kContentHorizontalMargin;
    final rightPadding = leftPadding;

    return Padding(
      padding: EdgeInsets.only(
        left: leftPadding,
        right: rightPadding,
        bottom: MediaQuery.of(context).padding.bottom + kContentVerticalPadding,
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
              color: kGreyLabelColour,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _loadingMessage,
            style: const TextStyle(color: kGreyLabelColour, fontSize: kFontSizeBody),
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
              const Icon(Icons.error_outline, color: kAccentColour, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(color: kAccentColour, fontSize: kFontSizeBody),
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
                color: kAccentColour.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: kAccentColour, fontSize: kFontSizeBody, fontWeight: FontWeight.w500),
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

    return [
      // Summary
      if (data.summary.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: kSectionBottomPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kSummaryFontSize * kSummaryLineHeight * kSummaryMinLines + 8,
            ),
            child: Text(
              data.summary,
              style: const TextStyle(
                color: kSummaryColour,
                fontSize: kSummaryFontSize,
                fontWeight: FontWeight.w400,
                height: kSummaryLineHeight,
              ),
              strutStyle: const StrutStyle(
                fontSize: kSummaryFontSize,
                height: kSummaryLineHeight,
                forceStrutHeight: true,
              ),
              softWrap: true,
              maxLines: null,
            ),
          ),
        ),
      // Chart — skip client-side conversion when the API already returned
      // data in the requested unit.
      Builder(builder: (_) {
        final needsConversion = widget.isFahrenheit && !data.isFahrenheit;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TemperatureBarChart(
              chartData: chartData,
              averageTemperature: data.average.mean,
              trendSlope: data.trend.slope,
              isLoading: false,
              height: 800,
              isFahrenheit: widget.isFahrenheit,
              needsConversion: needsConversion,
            ),
            const SizedBox(height: kSectionBottomPadding),
            // Average text
            Padding(
              padding: const EdgeInsets.only(bottom: kSectionBottomPadding),
              child: Text(
                'Average: ${formatTemperature(data.average.mean, isFahrenheit: widget.isFahrenheit, convert: needsConversion)}',
                style: const TextStyle(color: kAverageColour, fontSize: kFontSizeBody),
              ),
            ),
            // Trend text
            Padding(
              padding: const EdgeInsets.only(bottom: kSectionBottomPadding),
              child: Text(
                formatTrendSlope(data.trend.slope, isFahrenheit: widget.isFahrenheit, convert: needsConversion),
                style: const TextStyle(color: kTrendColour, fontSize: kFontSizeBody),
              ),
            ),
          ],
        );
      }),
      // Completeness notice
      Builder(builder: (context) {
        final currentYear = DateTime.now().year;
        final loadedYears = data.values.map((v) => v.year).toSet();
        final metaMissing = (data.metadata?.missingYears ?? []).map((m) => m.year).toList();
        final absent = detectAbsentYears(loadedYears, metaMissing);
        final allMissing = [...metaMissing, ...absent]..sort();
        // Exclude the current year: API may return it but it has no full-year data yet.
        final effectiveLoaded = loadedYears.where((y) => y < currentYear && !metaMissing.contains(y)).length;
        const totalExpected = 50; // rolling 50-year window
        final completeness = effectiveLoaded / totalExpected * 100;

        DebugUtils.logLazy(() =>
            'PeriodPage(${widget.periodKey}): metaMissing=$metaMissing, absent=$absent, effectiveLoaded=$effectiveLoaded, completeness=${completeness.toStringAsFixed(0)}%');

        return Padding(
          padding: const EdgeInsets.only(bottom: kSectionBottomPadding),
          child: CompletenessSection(
            allMissing: allMissing,
            completeness: completeness,
            isRetrying: _isLoading,
            onRetry: _isLoading
                ? null
                : () {
                    _lastFetchKey = '';
                    _fetchData(bypassCache: true);
                  },
          ),
        );
      }),
    ];
  }

}
