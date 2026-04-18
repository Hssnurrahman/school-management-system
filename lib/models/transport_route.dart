class TransportRoute {
  final String id;
  final String routeName;
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final List<String> stops;
  final String status;

  TransportRoute({
    required this.id,
    required this.routeName,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleNumber,
    required this.stops,
    this.status = 'Active',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'routeName': routeName,
        'driverName': driverName,
        'driverPhone': driverPhone,
        'vehicleNumber': vehicleNumber,
        'stops': stops,
        'status': status,
      };

  factory TransportRoute.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'];
    final List<String> stops;
    if (rawStops is List) {
      stops = rawStops.cast<String>();
    } else if (rawStops is String && rawStops.isNotEmpty) {
      stops = rawStops.split('|');
    } else {
      stops = [];
    }
    return TransportRoute(
      id: json['id'],
      routeName: json['routeName'],
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      vehicleNumber: json['vehicleNumber'],
      stops: stops,
      status: json['status'] ?? 'Active',
    );
  }
}
