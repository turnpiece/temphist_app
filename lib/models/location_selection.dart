class LocationSelection {
  final String location;
  final String displayLocation;
  final DateTime selectedAt;
  final int count;

  const LocationSelection({
    required this.location,
    required this.displayLocation,
    required this.selectedAt,
    required this.count,
  });

  factory LocationSelection.fromJson(Map<String, dynamic> json) =>
      LocationSelection(
        location: json['location'] as String,
        displayLocation: json['displayLocation'] as String,
        selectedAt:
            DateTime.fromMillisecondsSinceEpoch(json['selectedAt'] as int),
        count: json['count'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'location': location,
        'displayLocation': displayLocation,
        'selectedAt': selectedAt.millisecondsSinceEpoch,
        'count': count,
      };

  LocationSelection increment(DateTime at) => LocationSelection(
        location: location,
        displayLocation: displayLocation,
        selectedAt: at,
        count: count + 1,
      );
}
