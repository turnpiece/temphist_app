class LocationVisit {
  final String location;
  final String displayLocation;
  final DateTime visitedAt;

  const LocationVisit({
    required this.location,
    required this.displayLocation,
    required this.visitedAt,
  });

  factory LocationVisit.fromJson(Map<String, dynamic> json) => LocationVisit(
        location: json['location'] as String,
        displayLocation: json['displayLocation'] as String,
        visitedAt:
            DateTime.fromMillisecondsSinceEpoch(json['visitedAt'] as int),
      );

  Map<String, dynamic> toJson() => {
        'location': location,
        'displayLocation': displayLocation,
        'visitedAt': visitedAt.millisecondsSinceEpoch,
      };
}
