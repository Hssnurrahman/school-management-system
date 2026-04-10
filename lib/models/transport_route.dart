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
        'stops': stops.join('|'),
        'status': status,
      };

  factory TransportRoute.fromJson(Map<String, dynamic> json) => TransportRoute(
        id: json['id'],
        routeName: json['routeName'],
        driverName: json['driverName'],
        driverPhone: json['driverPhone'],
        vehicleNumber: json['vehicleNumber'],
        stops: (json['stops'] as String).split('|'),
        status: json['status'] ?? 'Active',
      );
}
