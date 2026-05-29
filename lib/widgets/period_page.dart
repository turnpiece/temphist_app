import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import '../models/period_temperature_data.dart';
import '../services/temperature_service.dart';
import '../services/period_cache_service.dart';
import '../utils/date_utils.dart';
import '../utils/debug_utils.dart';
import '../utils/temperature_utils.dart';
import 'completeness_section.dart';
import 'gradient_spinner.dart';
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

  /// GPS coordinates used for Hive cache key. Optional — cache is skipped
  /// if not provided (e.g. when using default location).
  final double? latitude;
  final double? longitude;

  /// Whether to display temperatures in Fahrenheit.
  final bool isFahrenheit;

  /// IANA timezone identifier for the selected city (e.g. "America/Los_Angeles").
  /// When provided, the "use yesterday" cutoff is evaluated against the city's
  /// local hour rather than the device clock.
  final String? locationTimezone;

  /// Optional scroll controller for the page's internal scroll view.
  final ScrollController? scrollController;

  /// Optional widget inserted above the chart content inside the scroll view.
  final Widget? topContent;

  /// Called once data loads with the trend slope (°C/decade, always Celsius).
  final void Function(double slope)? onTrendLoaded;

  const PeriodPage({
    super.key,
    required this.periodKey,
    required this.periodLabel,
    required this.location,
    this.displayLocation,
    this.latitude,
    this.longitude,
    this.isFahrenheit = false,
    this.locationTimezone,
    this.scrollController,
    this.topContent,
    this.onTrendLoaded,
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

  // Timestamp of the last successful data load — used to gate the silent
  // forecast refresh check on resume (daily period only).
  DateTime? _dataLoadedAt;

  // Generation counter — incremented whenever location/unit changes so that
  // any in-flight fetch from the previous configuration is discarded.
  int _fetchGeneration = 0;

  TemperatureChartPresentation? get chartPresentation {
    final data = _data;
    if (data == null || data.values.isEmpty) {
      return null;
    }

    final currentYear = DateTime.now().year;
    final chartData = data.values
        .map(
          (v) => TemperatureChartData(
            year: v.year.toString(),
            temperature: v.temperature,
            isCurrentYear: v.year == currentYear,
            hasData: true,
            anomaly: v.anomaly,
          ),
        )
        .toList();

    final needsConversion = widget.isFahrenheit && !data.isFahrenheit;
    return buildTemperatureChartPresentation(
      context: context,
      chartData: chartData,
      averageTemperature: data.average.mean,
      isFahrenheit: widget.isFahrenheit,
      needsConversion: needsConversion,
      standardDeviation: data.standardDeviation,
    );
  }

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
    final timezoneChanged = oldWidget.locationTimezone != widget.locationTimezone;
    if (locationChanged || unitChanged || timezoneChanged) {
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
    DateTime dateRef = DateTime.now();
    if (widget.locationTimezone != null) {
      try {
        final location = tz.getLocation(widget.locationTimezone!);
        dateRef = tz.TZDateTime.now(location);
      } catch (_) {
        // Unknown timezone — fall back to device clock.
      }
    }
    final useYesterday = dateRef.hour < kUseYesterdayHourThreshold;
    final dateToUse =
        useYesterday ? dateRef.subtract(const Duration(days: 1)) : dateRef;
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
      final locationTz = widget.locationTimezone;
      final localToday = locationTz != null ? localTodayIn(locationTz) : null;
      if (bypassCache) {
        // Evict only this period's entry from the in-memory service cache so
        // the retry goes to the network without disturbing other periods.
        TemperatureService.evictCacheEntry(
          widget.periodKey,
          widget.location,
          _identifier,
          unitGroup: unitGroup,
          localToday: localToday,
        );
      }
      PeriodTemperatureData? data;
      if (!bypassCache && lat != null && lon != null) {
        data = await PeriodCacheService.get(
          widget.periodKey,
          lat,
          lon,
          _identifier,
          unitGroup: unitGroup,
          localToday: localToday,
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
          localToday: localToday,
          onFallbackToSync: () {
            if (!mounted || _fetchGeneration != generation || !_isLoading) {
              return;
            }
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
          DateTime? expiresAt;
          if (widget.periodKey == 'daily' && locationTz != null && localToday != null) {
            expiresAt = DateTime.now().add(timeUntilNextLocalMidnight(locationTz));
          }
          await PeriodCacheService.put(
            widget.periodKey,
            lat,
            lon,
            _identifier,
            data,
            unitGroup: unitGroup,
            localToday: localToday,
            expiresAt: expiresAt,
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
          _dataLoadedAt = DateTime.now();
        });
        // Always pass slope in °C/decade so the gradient is unit-independent.
        final slopeCelsius =
            data.isFahrenheit ? data.trend.slope * 5.0 / 9.0 : data.trend.slope;
        widget.onTrendLoaded?.call(slopeCelsius);
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
      return 'This is taking a while.';
    }
    return 'Still loading...';
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
      if (status == 422) {
        return 'Location not recognised. Check the spelling and try a more specific name (e.g. "Tokyo, Japan").';
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

  bool get hasData => _data != null;

  /// Called externally (e.g. on location change) to force a reload.
  void reload() {
    _lastFetchKey = '';
    _data = null;
    _fetchData(bypassCache: true);
  }

  /// Reload without bypassing the Hive cache. Use when the location has
  /// changed but cached data for the new position may still be valid.
  void softReload() {
    _lastFetchKey = '';
    _data = null;
    _fetchData(bypassCache: false);
  }

  /// Called on app resume (daily period only). Silently polls the forecast
  /// endpoint to check whether today's temperature has changed since the data
  /// was last loaded. If it has, fetches fresh daily data (for an updated
  /// summary) and patches the displayed data without showing a loading state.
  ///
  /// No-ops if: not the daily period, data was loaded recently (within
  /// [kForecastRefreshThreshold]), no data is present, or a load is in progress.
  Future<void> checkAndRefreshTodayIfStale() async {
    if (widget.periodKey != 'daily') return;
    final data = _data;
    if (data == null || _isLoading) return;
    if (_dataLoadedAt == null ||
        DateTime.now().difference(_dataLoadedAt!) < kForecastRefreshThreshold) {
      return;
    }

    final currentYear = DateTime.now().year;
    PeriodDataPoint? existing;
    for (final v in data.values) {
      if (v.year == currentYear) {
        existing = v;
        break;
      }
    }
    if (existing == null) return; // No current-year entry to compare against
    final existingTemp = existing.temperature; // pin before any await

    DebugUtils.logLazy(() =>
        'PeriodPage(daily): checking forecast for temperature update');

    final unitGroup = widget.isFahrenheit ? 'fahrenheit' : null;
    final locationTz = widget.locationTimezone;
    final localToday = locationTz != null ? localTodayIn(locationTz) : null;
    final service = TemperatureService();

    final forecastTemp = await service.fetchForecast(
      widget.location,
      unitGroup: unitGroup,
    );
    if (forecastTemp == null || !mounted || _data != data) return;

    // Reset the check timer regardless of whether data changed, so we don't
    // hammer the endpoint on rapid app switches.
    _dataLoadedAt = DateTime.now();

    if ((forecastTemp - existingTemp).abs() < 0.1) {
      DebugUtils.logLazy(() => 'PeriodPage(daily): forecast unchanged, no update needed');
      return;
    }

    DebugUtils.logLazy(() =>
        'PeriodPage(daily): forecast changed '
        '$existingTemp → $forecastTemp, refreshing daily data');

    // Evict in-memory cache so fetchPeriodData goes to the API.
    TemperatureService.evictCacheEntry(
      'daily',
      widget.location,
      _identifier,
      unitGroup: unitGroup,
      localToday: localToday,
    );

    PeriodTemperatureData? freshData;
    try {
      freshData = await service.fetchPeriodData(
        'daily',
        widget.location,
        _identifier,
        unitGroup: unitGroup,
        localToday: localToday,
        isCancelled: () => !mounted || _data != data,
      );
    } catch (e) {
      DebugUtils.logLazy(() =>
          'PeriodPage(daily): summary refresh failed ($e) — patching temperature only');
    }

    if (!mounted || _data != data) return;

    final patched = freshData ??
        data.withCurrentYearPatch(
          year: currentYear,
          temperature: forecastTemp,
        );

    // Update Hive cache with the patched data.
    final lat = widget.latitude;
    final lon = widget.longitude;
    if (lat != null && lon != null) {
      DateTime? expiresAt;
      if (locationTz != null && localToday != null) {
        expiresAt = DateTime.now().add(timeUntilNextLocalMidnight(locationTz));
      }
      unawaited(PeriodCacheService.put(
        'daily',
        lat,
        lon,
        _identifier,
        patched,
        unitGroup: unitGroup,
        localToday: localToday,
        expiresAt: expiresAt,
      ));
    }

    if (!mounted || _data != data) return;
    setState(() {
      _data = patched;
      _dataLoadedAt = DateTime.now();
      _lastFetchKey = _fetchKey;
    });
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

    return RefreshIndicator(
      onRefresh: () async {
        _lastFetchKey = '';
        await _fetchData(bypassCache: true);
      },
      color: kAccentColour,
      backgroundColor: kBackgroundColour,
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: _buildSlivers(context),
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context) {
    final slivers = <Widget>[];

    // Loading/error/empty states share the same horizontal padding as the
    // rest of the page content so messages aren't flush to the screen edge.
    final sidePadding = EdgeInsets.symmetric(
      horizontal: kScreenPadding + kContentHorizontalMargin,
    );

    if (widget.topContent != null) {
      slivers.add(SliverToBoxAdapter(child: widget.topContent!));
    }

    if (_data == null && _error == null) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(padding: sidePadding, child: _buildLoadingState()),
      ));
      return slivers;
    }

    if (_error != null) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(padding: sidePadding, child: _buildErrorState()),
      ));
      return slivers;
    }

    if (_data != null && _data!.values.isEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(padding: sidePadding, child: _buildEmptyState()),
      ));
      return slivers;
    }

    final data = _data!;
    final needsConversion = widget.isFahrenheit && !data.isFahrenheit;
    final presentation = chartPresentation;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallPhone = screenWidth < kSmallPhoneBreakpointWidth;
    final double contentHPadding = kScreenPadding + kContentHorizontalMargin;
    final bool isTablet = screenWidth >= kTabletBreakpointWidth;
    final double bubbleInnerHPadding = isTablet ? 20.0 : 12.0;

    if (data.summary.isNotEmpty) {
      final double summaryLineCount = isTablet
          ? kSummaryMinLinesTablet
          : kSummaryMinLines;
      final double summaryBubbleHeight =
          kSummaryFontSize * kSummaryLineHeight * summaryLineCount +
              kSummaryBubbleVerticalPadding * 2;
      final double sideMargin =
          isSmallPhone ? 0 : kScreenPadding + kContentHorizontalMargin;
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              left: sideMargin,
              right: sideMargin,
              bottom: kSectionBottomPadding,
            ),
            child: Container(
              constraints: BoxConstraints(minHeight: summaryBubbleHeight),
              padding: EdgeInsets.symmetric(
                horizontal:
                    isSmallPhone ? kScreenPadding + kContentHorizontalMargin : bubbleInnerHPadding,
                vertical: kSummaryBubbleVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: kSummaryBubbleColour.withValues(alpha: 0.3),
                borderRadius: isSmallPhone
                    ? BorderRadius.zero
                    : BorderRadius.circular(kBubbleBorderRadius),
              ),
              child: Center(
                child: Text(
                  data.summary,
                  style: const TextStyle(
                    color: kSummaryTextColour,
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
          ),
        ),
      );
    }

    if (presentation != null) {
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedChartAxisHeaderDelegate(
            child: TemperatureChartTopAxis(presentation: presentation),
          ),
        ),
      );
    }

    slivers.add(
      SliverToBoxAdapter(
        child: TemperatureBarChart(
          chartData: presentation?.styledChartData ?? [],
          averageTemperature: data.average.mean,
          trendSlope: data.trend.slope,
          isLoading: false,
          height: kChartHeight,
          isFahrenheit: widget.isFahrenheit,
          needsConversion: needsConversion,
          showTemperatureAxis: false,
          presentation: presentation,
        ),
      ),
    );

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(
            top: kSectionTopPadding,
            left: isSmallPhone ? 0 : contentHPadding,
            right: isSmallPhone ? 0 : contentHPadding,
            bottom: kSectionBottomPadding,
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallPhone ? contentHPadding : bubbleInnerHPadding,
              vertical: kSummaryBubbleVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: kStatsBubbleColour.withValues(alpha: 0.4),
              borderRadius:
                  isSmallPhone ? BorderRadius.zero : BorderRadius.circular(kBubbleBorderRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(
                  'Average',
                  formatTemperature(data.average.mean,
                      isFahrenheit: widget.isFahrenheit,
                      convert: needsConversion),
                  kAverageColour,
                ),
                if (data.standardDeviation != null) ...[
                  const SizedBox(height: 6),
                  _buildStatRow(
                    'Standard deviation',
                    formatTemperature(data.standardDeviation!,
                        isFahrenheit: widget.isFahrenheit,
                        convert: needsConversion),
                    kStdDevColour,
                  ),
                ],
                const SizedBox(height: 6),
                _buildStatRow(
                  'Trend',
                  formatTrendValue(data.trend.slope,
                      slopeError: data.trend.slopeError,
                      isFahrenheit: widget.isFahrenheit,
                      convert: needsConversion),
                  kTrendColour,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(
            left: contentHPadding,
            right: contentHPadding,
            bottom:
                MediaQuery.of(context).padding.bottom + kContentVerticalPadding,
          ),
          child: _buildCompletenessSection(data),
        ),
      ),
    );

    return slivers;
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientSpinner.data(),
          const SizedBox(height: 16),
          Text(
            _loadingMessage.isNotEmpty
                ? _loadingMessage
                : 'Loading ${widget.periodLabel.toLowerCase()} temperature data...',
            style: const TextStyle(
                color: kGreyLabelColour, fontSize: kFontSizeBody),
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
          const Icon(Icons.thermostat_outlined,
              color: kGreyLabelColour, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No temperature data found for this location. The area may not have coverage — try a more specific name, e.g. "London, United Kingdom".',
              style: const TextStyle(
                  color: kGreyLabelColour, fontSize: kFontSizeBody),
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
              const Icon(Icons.error_outline, color: kErrorColour, size: 35),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(
                      color: kErrorColour, fontSize: kFontSizeBody),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              label: 'Retry loading ${widget.periodLabel.toLowerCase()} data',
              button: true,
              child: GestureDetector(
                onTap: () => _fetchData(bypassCache: true),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kErrorColour.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                        color: kErrorColour,
                        fontSize: kFontSizeBody,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color colour) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: kStatsFontSize, color: colour),
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessSection(PeriodTemperatureData data) {
    final currentYear = DateTime.now().year;
    final loadedYears = data.values.map((v) => v.year).toSet();
    final metaMissing =
        (data.metadata?.missingYears ?? []).map((m) => m.year).toList();
    final absent = detectAbsentYears(loadedYears, metaMissing);
    final allMissing = [...metaMissing, ...absent]..sort();
    final effectiveLoaded = loadedYears
        .where((y) => y < currentYear && !metaMissing.contains(y))
        .length;
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
  }
}

class _PinnedChartAxisHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  const _PinnedChartAxisHeaderDelegate({required this.child});

  @override
  double get minExtent => kTemperatureChartTopAxisHeight;

  @override
  double get maxExtent => kTemperatureChartTopAxisHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedChartAxisHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
