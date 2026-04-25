import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/popular_locations.dart';
import '../services/location_history_service.dart';
import '../services/temperature_service.dart';

class _SheetData {
  final List<String> recentLocations;
  final List<String> popularLocations;

  const _SheetData({
    required this.recentLocations,
    required this.popularLocations,
  });
}

/// Full-screen location selector pushed from below like a sheet.
///
/// "Current location" always shows the physical GPS location ([gpsLocation]).
/// [selectedLocation] is the location currently used for data — it may be a
/// manually chosen city that appears highlighted in recent or popular lists.
class LocationSelectorSheet extends StatefulWidget {
  /// The physical GPS-detected location string (e.g. "London, United Kingdom").
  /// Shown in the "Current location" section. Empty string hides the section.
  final String gpsLocation;

  /// The location currently selected for data fetching — may differ from
  /// [gpsLocation] when the user has manually chosen a city.
  final String selectedLocation;

  /// Called with the chosen API location string when the user picks one.
  /// The screen dismisses itself before invoking this.
  final void Function(String apiLocation) onLocationSelected;

  /// When false the close button is hidden and the barrier is non-dismissible,
  /// forcing the user to pick a city. Used on first launch when no location
  /// has been determined.
  final bool canDismiss;

  const LocationSelectorSheet({
    super.key,
    required this.gpsLocation,
    required this.selectedLocation,
    required this.onLocationSelected,
    this.canDismiss = true,
  });

  /// Show the location selector as a full-screen modal that slides up.
  ///
  /// Uses [showGeneralDialog] so the modal fills the entire screen in all
  /// orientations and properly blocks gestures from the underlying route
  /// (which fixes scroll issues that occur with PageRouteBuilder in landscape).
  static Future<void> show(
    BuildContext context, {
    required String gpsLocation,
    required String selectedLocation,
    required void Function(String) onLocationSelected,
    bool canDismiss = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: canDismiss,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => LocationSelectorSheet(
        gpsLocation: gpsLocation,
        selectedLocation: selectedLocation,
        onLocationSelected: onLocationSelected,
        canDismiss: canDismiss,
      ),
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  late final Future<_SheetData> _dataFuture;
  bool _showAllRecent = false;
  bool _showAllPopular = false;

  static const int _initialCount = 5;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_SheetData> _loadData() async {
    final history = await LocationHistoryService.getAll();

    // Build a set of excluded city names (first comma-segment, lower-cased) so
    // that format differences between GPS results ("London, Greater London, UK")
    // and API results ("London, United Kingdom") don't cause duplicates.
    String cityName(String loc) => loc.split(',').first.trim().toLowerCase();
    final excludedCities = {
      cityName(widget.gpsLocation),
    };
    bool isExcluded(String loc) =>
        loc.isEmpty || excludedCities.contains(cityName(loc));

    // Recent list: GPS history minus the GPS location itself.
    // The selected location (if manually chosen) stays in the list so it can
    // be shown as selected.
    final recent = history.where((l) => !isExcluded(l)).toList();

    // Fetch pre-approved locations from API; fall back to the bundled list if
    // the request fails (e.g. offline) or returns an unexpected format.
    // Exclude GPS history city names to avoid duplicates with recent list.
    final recentCities = {for (final h in history) cityName(h)};
    bool isExcludedFromPopular(String loc) =>
        isExcluded(loc) || recentCities.contains(cityName(loc));

    List<String> popular;
    try {
      final allPreapproved =
          await TemperatureService().fetchPreapprovedLocations();
      popular = allPreapproved
          .where((l) => !isExcludedFromPopular(l))
          .toList()
        ..shuffle();
    } catch (_) {
      popular = kPopularLocations
          .where((l) => !isExcludedFromPopular(l))
          .toList()
        ..shuffle();
    }

    return _SheetData(recentLocations: recent, popularLocations: popular);
  }

  @override
  Widget build(BuildContext context) {
    // Material (not Scaffold) so that showGeneralDialog gives us the full
    // screen size correctly in both portrait and landscape.
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackgroundColour, kBackgroundColourDark],
          ),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth >= kTabletBreakpointWidth;
          final contentWidth = isTablet
              ? kTabletMaxContentWidth.clamp(0.0, constraints.maxWidth)
              : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: contentWidth,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header row with title and optional close button
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, widget.canDismiss ? 8 : 20, 12),
                      child: Row(
                        children: [
                          Text(
                            widget.canDismiss ? 'Choose location' : 'Choose your location',
                            style: TextStyle(
                              color: kTextPrimaryColour,
                              fontSize: kFontSizeBody,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (widget.canDismiss)
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: kGreyLabelColour,
                                size: kIconSize + 2,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                        ],
                      ),
                    ),
                    Divider(
                      color: kGreyLabelColour.withValues(alpha: 0.3),
                      height: 1,
                    ),
                    // Scrollable content
                    Expanded(
                      child: FutureBuilder<_SheetData>(
                        future: _dataFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(color: kAccentColour),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return Center(
                              child: Text(
                                'Could not load locations',
                                style: TextStyle(
                                  color: kGreyLabelColour,
                                  fontSize: kFontSizeBody,
                                ),
                              ),
                            );
                          }
                          return _buildContent(snapshot.data!, isTablet: isTablet);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Returns [all] with the selected item moved to index 0 (if present).
  List<String> _withSelectedFirst(List<String> all) {
    final i = all.indexWhere(_isSelected);
    if (i <= 0) return all; // not found or already first
    return [all[i], ...all.sublist(0, i), ...all.sublist(i + 1)];
  }

  Widget _buildContent(_SheetData data, {bool isTablet = false}) {
    final orderedRecent = _withSelectedFirst(data.recentLocations);
    final orderedPopular = _withSelectedFirst(data.popularLocations);

    final visibleRecent = isTablet || _showAllRecent
        ? orderedRecent
        : orderedRecent.take(_initialCount).toList();
    final popularInitialCount =
        (10 - data.recentLocations.length).clamp(_initialCount, 10);
    final showAllPopular = isTablet || _showAllPopular;
    final visiblePopular = showAllPopular
        ? orderedPopular
        : orderedPopular.take(popularInitialCount).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // "Current location" shows the physical GPS location, if known.
        // Always a single full-width row.
        if (widget.gpsLocation.isNotEmpty) ...[
          _SectionHeader('Current', color: kBarCurrentYearColour),
          _LocationRow(
            apiLocation: widget.gpsLocation,
            isSelected: widget.selectedLocation == widget.gpsLocation,
            selectedColor: kBarCurrentYearColour,
            onTap: widget.selectedLocation == widget.gpsLocation && widget.canDismiss
                ? null
                : () => _select(widget.gpsLocation),
          ),
        ],
        // Recent — two-column grid on tablets, single column on phones.
        if (data.recentLocations.isNotEmpty) ...[
          _SectionHeader('Recent', color: kAccentColour),
          if (isTablet)
            _buildTwoColumnGrid(visibleRecent, kAccentColour)
          else ...[
            for (final loc in visibleRecent)
              _LocationRow(
                apiLocation: loc,
                isSelected: _isSelected(loc),
                selectedColor: kAccentColour,
                onTap: _isSelected(loc) && widget.canDismiss ? null : () => _select(loc),
              ),
            if (data.recentLocations.length > _initialCount && !_showAllRecent)
              _ShowMoreButton(
                onTap: () => setState(() => _showAllRecent = true),
              ),
          ],
        ],
        // Popular — two-column grid on tablets, single column on phones.
        if (data.popularLocations.isNotEmpty) ...[
          _SectionHeader('Popular', color: kAverageColour),
          if (isTablet)
            _buildTwoColumnGrid(visiblePopular, kAverageColour)
          else ...[
            for (final loc in visiblePopular)
              _LocationRow(
                apiLocation: loc,
                isSelected: _isSelected(loc),
                selectedColor: kAverageColour,
                onTap: _isSelected(loc) && widget.canDismiss ? null : () => _select(loc),
              ),
            if (data.popularLocations.length > popularInitialCount && !showAllPopular)
              _ShowMoreButton(
                onTap: () => setState(() => _showAllPopular = true),
              ),
          ],
        ],
      ],
    );
  }

  /// Renders [locations] as pairs of side-by-side [_LocationRow]s.
  Widget _buildTwoColumnGrid(List<String> locations, Color selectedColor) {
    final rows = <Widget>[];
    for (int i = 0; i < locations.length; i += 2) {
      final left = locations[i];
      final right = i + 1 < locations.length ? locations[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _LocationRow(
                  apiLocation: left,
                  isSelected: _isSelected(left),
                  selectedColor: selectedColor,
                  onTap: _isSelected(left) && widget.canDismiss ? null : () => _select(left),
                ),
              ),
              VerticalDivider(
                color: kGreyLabelColour.withValues(alpha: 0.15),
                width: 1,
              ),
              Expanded(
                child: right != null
                    ? _LocationRow(
                        apiLocation: right,
                        isSelected: _isSelected(right),
                        selectedColor: selectedColor,
                        onTap: _isSelected(right) && widget.canDismiss ? null : () => _select(right),
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  /// True when [loc] is the currently active selected location.
  bool _isSelected(String loc) {
    String city(String l) => l.split(',').first.trim().toLowerCase();
    return city(loc) == city(widget.selectedLocation);
  }

  void _select(String apiLocation) {
    // Clear the main screen's data before popping so the loading state is
    // already showing when the dismiss animation plays — not the old chart.
    widget.onLocationSelected(apiLocation);
    Navigator.of(context).pop();
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionHeader(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: kFontSizeBody - 4,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String apiLocation;
  final bool isSelected;
  /// The colour used when this row is selected (matches the section colour).
  final Color selectedColor;
  final VoidCallback? onTap;

  const _LocationRow({
    required this.apiLocation,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  String get _displayName => apiLocation.split(',').first.trim();

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : kTextPrimaryColour;

    return InkWell(
      onTap: onTap,
      splashColor: kAccentColour.withValues(alpha: 0.1),
      highlightColor: kAccentColour.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Icon(
                Icons.location_on_outlined,
                size: kIconSize + 3,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                _displayName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: kFontSizeBody,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.check,
                size: kIconSize + 3,
                color: kBarCurrentYearColour,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShowMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Show more...',
          style: TextStyle(
            color: kGreyLabelColour,
            fontSize: kFontSizeBody - 2,
          ),
        ),
      ),
    );
  }
}
