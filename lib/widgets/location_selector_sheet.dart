import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
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
        ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
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

  // Search state
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _searchResults = [];
  bool _searchLoading = false;
  Timer? _debounceTimer;

  static const int _initialCount = 5;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim();
    _debounceTimer?.cancel();

    if (query.length < 2) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _searchLoading = false;
      });
      return;
    }

    setState(() {
      _searchQuery = query;
      _searchLoading = true;
    });

    _debounceTimer = Timer(
      const Duration(milliseconds: 350),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    try {
      final results = await TemperatureService().searchLocations(query);
      if (!mounted || _searchQuery != query) return;
      setState(() {
        _searchResults = results;
        _searchLoading = false;
      });
    } catch (_) {
      if (!mounted || _searchQuery != query) return;
      setState(() {
        _searchLoading = false;
      });
    }
  }

  void _onSearchSubmitted(String value) {
    final query = value.trim();
    if (query.length < 2) return;
    _debounceTimer?.cancel();
    // Select the top result on Enter/Go — only if there are verified results.
    if (_searchResults.isNotEmpty) {
      _select(_searchResults.first);
    }
    // No results → do nothing; the user can refine their query.
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _searchLoading = false;
    });
  }

  Future<_SheetData> _loadData() async {
    final visits = await LocationHistoryService.getAll();
    final history = visits.map((v) => v.location).toList();

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
      popular = allPreapproved.where((l) => !isExcludedFromPopular(l)).toList()
        ..shuffle();
    } catch (_) {
      popular = [];
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
                      padding: EdgeInsets.fromLTRB(
                          20, 16, widget.canDismiss ? 8 : 20, 12),
                      child: Row(
                        children: [
                          Text(
                            widget.canDismiss
                                ? 'Choose location'
                                : 'Choose your location',
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
                    // Search field
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: _SearchField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: _onSearchSubmitted,
                        onClear: _clearSearch,
                      ),
                    ),
                    // Scrollable content — search results or normal lists
                    Expanded(
                      child: _searchQuery.isNotEmpty
                          ? _buildSearchContent()
                          : FutureBuilder<_SheetData>(
                              future: _dataFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState !=
                                    ConnectionState.done) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                        color: kLocationPopularColour),
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
                                return _buildContent(snapshot.data!,
                                    isTablet: isTablet);
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

  Widget _buildSearchContent() {
    if (_searchLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kLocationPopularColour),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No locations found.\nTry a more specific search, e.g. "Birmingham, Alabama, US".',
          textAlign: TextAlign.center,
          style: TextStyle(color: kGreyLabelColour, fontSize: kFontSizeBody),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final loc in _searchResults)
          _LocationRow(
            apiLocation: loc,
            isSelected: _isSelected(loc),
            selectedColor: kBarCurrentYearColour,
            showDetails: true,
            // Always tappable in search — tapping a selected result just dismisses.
            onTap: () => _select(loc),
          ),
      ],
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
          _SectionHeader('Current', color: kLocationRecentColour),
          _LocationRow(
            apiLocation: widget.gpsLocation,
            isSelected: widget.selectedLocation == widget.gpsLocation,
            selectedColor: kBarCurrentYearColour,
            onTap: () => _select(widget.gpsLocation),
          ),
        ],
        // Recent — two-column grid on tablets, single column on phones.
        if (data.recentLocations.isNotEmpty) ...[
          _SectionHeader('Recent', color: kLocationRecentColour),
          if (isTablet)
            _buildTwoColumnGrid(visibleRecent, kBarCurrentYearColour)
          else ...[
            for (final loc in visibleRecent)
              _LocationRow(
                apiLocation: loc,
                isSelected: _isSelected(loc),
                selectedColor: kBarCurrentYearColour,
                onTap: () => _select(loc),
              ),
            if (data.recentLocations.length > _initialCount && !_showAllRecent)
              _ShowMoreButton(
                onTap: () => setState(() => _showAllRecent = true),
              ),
          ],
        ],
        // Popular — two-column grid on tablets, single column on phones.
        if (data.popularLocations.isNotEmpty) ...[
          _SectionHeader('Popular', color: kLocationRecentColour),
          if (isTablet)
            _buildTwoColumnGrid(visiblePopular, kBarCurrentYearColour)
          else ...[
            for (final loc in visiblePopular)
              _LocationRow(
                apiLocation: loc,
                isSelected: _isSelected(loc),
                selectedColor: kBarCurrentYearColour,
                onTap: () => _select(loc),
              ),
            if (data.popularLocations.length > popularInitialCount &&
                !showAllPopular)
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
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _LocationRow(
                    apiLocation: left,
                    isSelected: _isSelected(left),
                    selectedColor: selectedColor,
                    onTap: () => _select(left),
                    margin: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: right != null
                      ? _LocationRow(
                          apiLocation: right,
                          isSelected: _isSelected(right),
                          selectedColor: selectedColor,
                          onTap: () => _select(right),
                          margin: EdgeInsets.zero,
                        )
                      : const SizedBox(),
                ),
              ],
            ),
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

  /// When true, show state/country as a secondary line below the city name.
  /// Used in search results to disambiguate same-named cities.
  final bool showDetails;
  final EdgeInsetsGeometry margin;

  const _LocationRow({
    required this.apiLocation,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
    this.showDetails = false,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 8),
  });

  String get _displayName => apiLocation.split(',').first.trim();

  /// City + admin1 for search results, e.g.:
  ///   "Birmingham, Alabama, United States" → "Birmingham, Alabama"
  ///   "Birmingham, United States"          → "Birmingham"
  String get _displayNameWithAdmin1 {
    final parts = apiLocation.split(',');
    if (parts.length >= 3) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return parts[0].trim();
  }

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : kTextPrimaryColour;
    final cc = TemperatureService.countryCodeFor(apiLocation);
    final flag = cc != null ? TemperatureService.flagEmoji(cc) : null;

    final label = showDetails ? _displayNameWithAdmin1 : _displayName;

    return Semantics(
      label: isSelected ? '$label, selected' : label,
      button: true,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: kTextPrimaryColour.withValues(alpha: isSelected ? 0.16 : 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: kAccentColour.withValues(alpha: 0.1),
          highlightColor: kAccentColour.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Flag emoji when a country code is known; pin icon otherwise.
                if (flag != null)
                  SizedBox(
                    width: kIconSize + 3,
                    child: Text(
                      flag,
                      style: const TextStyle(fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Icon(
                    Icons.location_on_outlined,
                    size: kIconSize + 3,
                    color: color,
                  ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    label,
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
                    color: color,
                  ),
                ],
              ],
            ),
          ),
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
      padding: const EdgeInsets.only(left: 20, bottom: 8),
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

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final void Function(String) onSubmitted;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted && _hasFocus != _focusNode.hasFocus) {
      setState(() => _hasFocus = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: _focusNode,
      controller: widget.controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.go,
      autofocus: false,
      autocorrect: false,
      enableSuggestions: false,
      style: TextStyle(
        color: _hasFocus ? kTextPrimaryColour : kLocationPopularColour,
        fontSize: kFontSizeBody,
      ),
      decoration: InputDecoration(
        hintText: 'Search…',
        hintStyle: TextStyle(
          color: kGreyLabelColour.withValues(alpha: 0.7),
          fontSize: kFontSizeBody,
        ),
        prefixIcon: const Icon(Icons.search,
            color: kGreyLabelColour, size: kIconSize + 3),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close,
                    color: kGreyLabelColour, size: kIconSize + 1),
                onPressed: widget.onClear,
              )
            : null,
        filled: true,
        fillColor: kBackgroundColour.withValues(alpha: 0.6),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: kGreyLabelColour.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: kGreyLabelColour.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: kLocationPopularColour.withValues(alpha: 0.45)),
        ),
      ),
    );
  }
}
