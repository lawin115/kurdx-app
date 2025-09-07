class DriverDashboardStats {
  final int todaysDeliveries;
  final double todaysCollected;
  final int pendingDeliveries;

  DriverDashboardStats({
    required this.todaysDeliveries,
    required this.todaysCollected,
    required this.pendingDeliveries,
  });

  factory DriverDashboardStats.fromJson(Map<String, dynamic> json) {
    return DriverDashboardStats(
      todaysDeliveries: json['todays_deliveries'] ?? 0,
      todaysCollected: double.tryParse(json['todays_collected']?.toString() ?? '0.0') ?? 0.0,
      pendingDeliveries: json['pending_deliveries'] ?? 0,
    );
  }
}
