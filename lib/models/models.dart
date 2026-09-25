// lib/models/models.dart

class MonitoringData {
  final double suhu;
  final double tekanan;
  final String status;

  MonitoringData({required this.suhu, required this.tekanan, required this.status});

  factory MonitoringData.fromMap(Map<dynamic, dynamic> map) {
    return MonitoringData(
      // Mengubah ke double secara aman, mencegah error jika data yang masuk berupa integer
      suhu: (map['suhu'] ?? 0).toDouble(), 
      tekanan: (map['tekanan'] ?? 0).toDouble(),
      status: map['status'] ?? 'IDLE',
    );
  }
}

class BatchData {
  final int startTs;
  final double wasteKg;
  final double? fuelLiters;
  final String status;

  BatchData({required this.startTs, required this.wasteKg, this.fuelLiters, required this.status});
}