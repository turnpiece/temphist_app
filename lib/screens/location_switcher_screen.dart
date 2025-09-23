import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../models/explore_state.dart';
import '../constants.dart';

class LocationSwitcherScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback? onLocationSelected;
  final VoidCallback? onSettingsTapped;

  const LocationSwitcherScreen({
    super.key,
    required this.appState,
    this.onLocationSelected,
    this.onSettingsTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColour,
      appBar: AppBar(
        backgroundColor: kBackgroundColour,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kTextColour),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Location',
          style: TextStyle(
            color: kTextColour,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: kTextColour),
            onPressed: () {
              Navigator.of(context).pop();
              onSettingsTapped?.call();
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, child) {
          final visitedLocations = appState.visitedLocations;
          final currentLocation = appState.currentLocation;

          if (visitedLocations.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visitedLocations.length + (visitedLocations.length == 1 ? 1 : 0), // Add 1 for message if only one location
            itemBuilder: (context, index) {
              // If we have only one location, show the message after the location
              if (visitedLocations.length == 1 && index == 1) {
                return _buildSingleLocationMessage(context);
              }
              
              final location = visitedLocations[index];
              final isCurrentLocation = currentLocation?.displayName == location.displayName;

              return _buildLocationTile(
                context,
                location: location,
                isCurrentLocation: isCurrentLocation,
                onTap: () {
                  HapticFeedback.lightImpact();
                  appState.setCurrentLocation(location);
                  appState.resetToToday(); // Reset pager to Today when location changes
                  onLocationSelected?.call();
                  Navigator.of(context).pop();
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: kTextColour.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Locations Yet',
              style: TextStyle(
                color: kTextColour.withOpacity(0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Visit different locations to build your list',
              style: TextStyle(
                color: kTextColour.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleLocationMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColour.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kTextColour.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: kTextColour.withOpacity(0.6),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "When you visit other locations they'll appear here.",
              style: TextStyle(
                color: kTextColour.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(
    BuildContext context, {
    required LocationInfo location,
    required bool isCurrentLocation,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentLocation ? kAccentColour.withOpacity(0.1) : kCardColour,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentLocation
            ? Border.all(color: kAccentColour.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrentLocation ? kAccentColour : kTextColour.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isCurrentLocation ? Icons.my_location : Icons.location_on,
            color: isCurrentLocation ? Colors.white : kTextColour.withOpacity(0.7),
            size: 20,
          ),
        ),
        title: Text(
          location.displayName,
          style: TextStyle(
            color: kTextColour,
            fontSize: 16,
            fontWeight: isCurrentLocation ? FontWeight.w600 : FontWeight.w500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: location.latitude != 0.0 && location.longitude != 0.0
            ? Text(
                '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                style: TextStyle(
                  color: kTextColour.withOpacity(0.6),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: isCurrentLocation
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kAccentColour,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : const Icon(
                Icons.chevron_right,
                color: kTextColour,
                size: 20,
              ),
        onTap: onTap,
      ),
    );
  }
}
