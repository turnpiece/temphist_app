import 'dart:async';

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

  /// Called once after the page successfully loads (or reloads) data.
  /// Useful for triggering downstream actions like showing a coachmark.
  final VoidCallback? onDataLoaded;

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
    this.onDataLoaded,
  });

  @override
  State<PeriodPage> createState() => PeriodPageState();
}

class PeriodPageState extends State<PeriodPage>
    with AutomaticKeepAliveClientMixin {
  static const int _connectingPhaseEndSeconds = 5;
  static const int _questionPhaseEndSeconds = 15;
  static const int _analyzingPhaseEndSeconds = 30;
  static const int _generatingPhaseEndSeconds = 45;
  static const int _longWaitPhaseEndSeconds = 60;
  static const int _veryLongWaitPhaseEndSeconds = 90;
  static const Duration _fallbackMessageMinDuration = Duration(seconds: 2);

  PeriodTemperatureData? _data;
  bool _isLoading = false;
  String? _error;
  String _loadingMessage = '';
  Timer? _loadingMessageTimer;
  DateTime? _loadingStartTime;
  DateTime? _fallbackMessageShownAt;
  bool _isShowingFallbackMessage = false;
  int _minLoadingPhaseFromProgress = 0;

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
    final locationChanged = oldWidget.location != widget.location;
    final unitChanged = oldWidget.isFahrenheit != widget.isFahrenheit;
    if (locationChanged || unitChanged) {
      DebugUtils.logLazy(() =>
          'PeriodPage(${widget.periodKey}): didUpdateWidget — '
          '${locationChanged ? "location: ${oldWidget.location} → ${widget.location}" : ""}'
          '${locationChanged && unitChanged ? ", " : ""}'
          '${unitChanged ? "unit: ${oldWidget.isFahrenheit ? "°F" : "°C"} → ${widget.isFahrenheit ? "°F" : "°C"}" : ""}'
          ' — clearing data and re-fetching');
      _fetchGeneration++;
      _lastFetchKey = '';
      _data = null;
      _error = null;
      _isLoading = false;
      _stopLoadingMessageCycle();
      _loadingMessage = _buildLoadingMessage(0, forcePhase: 0);
      _loadIfNeeded();
    }
  }

  @override
  void dispose() {
    _stopLoadingMessageCycle();
    super.dispose();
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
      _loadingMessage = _buildLoadingMessage(0, forcePhase: 0);
    });
    _startLoadingMessageCycle(generation);

    try {
      final lat = widget.latitude;
      final lon = widget.longitude;

      DebugUtils.logLazy(() =>
          'PeriodPage(${widget.periodKey}): fetching for ${widget.location}'
          ' (coords: ${lat != null ? "${lat.toStringAsFixed(3)},${lon?.toStringAsFixed(3)}" : "none — Hive cache skipped"})');

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
        DebugUtils.logLazy(() =>
            'PeriodPage(${widget.periodKey}): fetching from API for ${widget.location}');
        final service = TemperatureService();
        data = await service.fetchPeriodData(
          widget.periodKey,
          widget.location,
          _identifier,
          unitGroup: unitGroup,
          onFallbackToSync: () {
            if (!mounted || _fetchGeneration != generation || !_isLoading) return;
            _fallbackMessageShownAt = DateTime.now();
            _isShowingFallbackMessage = true;
            setState(() {
              _loadingMessage = 'Trying a different way to fetch the data...';
            });
          },
          onProgress: (status) {
            if (mounted && _fetchGeneration == generation) {
              final start = _loadingStartTime;
              final elapsedSeconds = start == null
                  ? 0
                  : DateTime.now().difference(start).inSeconds;
              // Preserve the early web-style narrative phases (connecting +
              // question) before allowing backend progress to accelerate copy.
              if (elapsedSeconds < _questionPhaseEndSeconds) return;
              final floor = status.isPending ? 2 : 3;
              if (floor > _minLoadingPhaseFromProgress) {
                _minLoadingPhaseFromProgress = floor;
                _updateLoadingMessage(generation);
              }
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
        await _ensureFallbackMessageVisibility(generation);
        if (!mounted || _fetchGeneration != generation) return;
        _stopLoadingMessageCycle();
        setState(() {
          _data = data;
          _isLoading = false;
          _lastFetchKey = _fetchKey;
        });
        widget.onDataLoaded?.call();
      }
    } on RateLimitException {
      if (mounted && _fetchGeneration == generation) {
        await _ensureFallbackMessageVisibility(generation);
        if (!mounted || _fetchGeneration != generation) return;
        _stopLoadingMessageCycle();
        setState(() {
          _isLoading = false;
          _error = 'Rate limit exceeded. Please wait a moment and try again.';
        });
      }
    } catch (e) {
      DebugUtils.logLazy(() => 'PeriodPage error (${widget.periodKey}): $e');
      if (mounted && _fetchGeneration == generation) {
        await _ensureFallbackMessageVisibility(generation);
        if (!mounted || _fetchGeneration != generation) return;
        _stopLoadingMessageCycle();
        setState(() {
          _isLoading = false;
          _error = _buildErrorMessage(e);
        });
      }
    }
  }

  void _startLoadingMessageCycle(int generation) {
    _stopLoadingMessageCycle();
    _loadingStartTime = DateTime.now();
    _minLoadingPhaseFromProgress = 0;
    _updateLoadingMessage(generation);
    _loadingMessageTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateLoadingMessage(generation);
    });
  }

  void _stopLoadingMessageCycle() {
    _loadingMessageTimer?.cancel();
    _loadingMessageTimer = null;
    _loadingStartTime = null;
    _fallbackMessageShownAt = null;
    _isShowingFallbackMessage = false;
    _minLoadingPhaseFromProgress = 0;
  }

  void _updateLoadingMessage(int generation) {
    if (!mounted ||
        !_isLoading ||
        _fetchGeneration != generation ||
        _isShowingFallbackMessage) {
      return;
    }
    final start = _loadingStartTime;
    if (start == null) return;
    final elapsedSeconds = DateTime.now().difference(start).inSeconds;
    final nextMessage = _buildLoadingMessage(
      elapsedSeconds,
      forcePhase: _minLoadingPhaseFromProgress,
    );
    if (nextMessage != _loadingMessage) {
      setState(() {
        _loadingMessage = nextMessage;
      });
    }
  }

  String _buildLoadingMessage(int elapsedSeconds, {int forcePhase = 0}) {
    final periodKey = widget.periodKey.toLowerCase();
    final displayCity = _extractDisplayCity();
    final elapsedPhase = _phaseIndexForElapsed(elapsedSeconds);
    final phase = elapsedPhase > forcePhase ? elapsedPhase : forcePhase;

    if (phase == 0) {
      return 'Connecting to the temperature data server...';
    }
    if (phase == 1) {
      if (periodKey == 'week') {
        return 'Has this past week been warmer or cooler than average in $displayCity?';
      }
      if (periodKey == 'month') {
        return 'Has this past month been warmer or cooler than average in $displayCity?';
      }
      if (periodKey == 'year') {
        return 'Has this past year been warmer or cooler than average in $displayCity?';
      }
      return 'Getting temperature data over the past $kHistoricalDataWindowYears years...';
    }
    if (phase == 2) {
      if (periodKey == 'week') {
        return 'Analysing weekly temperatures in $displayCity...';
      }
      if (periodKey == 'month') {
        return 'Analysing monthly temperatures in $displayCity...';
      }
      if (periodKey == 'year') {
        return 'Analysing yearly temperatures in $displayCity...';
      }
      return 'Analysing historical data for $displayCity...';
    }
    if (phase == 3) {
      if (periodKey == 'week') {
        return 'Generating weekly temperature comparison...';
      }
      if (periodKey == 'month') {
        return 'Generating monthly temperature comparison...';
      }
      if (periodKey == 'year') {
        return 'Generating yearly temperature comparison...';
      }
      return 'Generating temperature comparison chart...';
    }
    if (phase == 4) {
      return 'Still working on your ${widget.periodLabel.toLowerCase()} temperature comparison...';
    }
    if (phase == 5) {
      return 'This is taking longer than usual. We are still waiting for the server response...';
    }
    return 'Still loading. If this does not finish soon, please try retrying.';
  }

  int _phaseIndexForElapsed(int elapsedSeconds) {
    if (elapsedSeconds < _connectingPhaseEndSeconds) return 0;
    if (elapsedSeconds < _questionPhaseEndSeconds) return 1;
    if (elapsedSeconds < _analyzingPhaseEndSeconds) return 2;
    if (elapsedSeconds < _generatingPhaseEndSeconds) return 3;
    if (elapsedSeconds < _longWaitPhaseEndSeconds) return 4;
    if (elapsedSeconds < _veryLongWaitPhaseEndSeconds) return 5;
    return 6;
  }

  String _extractDisplayCity() {
    final raw = (widget.displayLocation?.isNotEmpty ?? false)
        ? widget.displayLocation!
        : widget.location;
    final parts = raw.split(',');
    if (parts.isEmpty) return raw;
    return parts.first.trim().isEmpty ? raw : parts.first.trim();
  }

  Future<void> _ensureFallbackMessageVisibility(int generation) async {
    if (!_isShowingFallbackMessage) return;
    final shownAt = _fallbackMessageShownAt;
    if (shownAt == null) return;
    final elapsed = DateTime.now().difference(shownAt);
    final remaining = _fallbackMessageMinDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    if (mounted && _fetchGeneration == generation) {
      _isShowingFallbackMessage = false;
    }
  }

  String _buildErrorMessage(Object error) {
    final periodName = widget.periodLabel.toLowerCase();

    if (error is TimeoutException || error is ApiTimeoutException) {
      return 'Request timed out while loading $periodName data. Please try again.';
    }
    if (error is JobPollingException) {
      return 'Server processing took too long for $periodName data. Please try again.';
    }
    if (error is AuthException) {
      return 'Authentication issue while loading $periodName data. Please try again.';
    }
    if (error is ApiException) {
      final status = error.statusCode;
      if (status == 429) {
        return 'Rate limit exceeded. Please wait a moment and try again.';
      }
      if (status >= 500) {
        return 'Server error while loading $periodName data. Please try again shortly.';
      }
      if (status == 0 && error.cause is TimeoutException) {
        return 'Request timed out while loading $periodName data. Please try again.';
      }
      return 'Unable to load $periodName data right now. Please try again.';
    }

    return 'Failed to load $periodName data. Please check your connection and try again.';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= kTabletBreakpointWidth;
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
          // Loading state — show whenever we have no data and no error,
          // regardless of _isLoading flag. This ensures the spinner appears
          // immediately when data is cleared (e.g. location/unit change)
          // without waiting for _fetchData's setState to fire.
          if (_data == null && _error == null) _buildLoadingState(),

          // Error state
          if (_error != null) _buildErrorState(),

          // Empty state — data returned but no values to display
          if (_data != null && _data!.values.isEmpty) _buildEmptyState(),

          // Data loaded
          if (_data != null && _data!.values.isNotEmpty) ..._buildDataContent(isTablet: isTablet),
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
            _loadingMessage.isNotEmpty
                ? _loadingMessage
                : 'Loading ${widget.periodLabel.toLowerCase()} temperature data...',
            style: const TextStyle(color: kGreyLabelColour, fontSize: kFontSizeBody),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Row(
        children: [
          const Icon(Icons.thermostat_outlined, color: kGreyLabelColour, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No ${widget.periodLabel.toLowerCase()} data available for this location. Try selecting a different location.',
              style: const TextStyle(color: kGreyLabelColour, fontSize: kFontSizeBody),
            ),
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
          Semantics(
            label: 'Retry loading ${widget.periodLabel.toLowerCase()} data',
            button: true,
            child: GestureDetector(
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
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDataContent({bool isTablet = false}) {
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
            constraints: BoxConstraints(
              minHeight: kSummaryFontSize * kSummaryLineHeight *
                  (isTablet ? kSummaryMinLinesTablet : kSummaryMinLines) + 8,
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
        const totalExpected = kHistoricalDataWindowYears;
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
