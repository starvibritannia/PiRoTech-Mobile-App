// lib/models/batch_model.dart

class Batch {
  final String sessionId;
  final int startTs;
  final int originalStartTs; // Wajib int
  final String startedBy;    // Ganti userId
  final double wasteKg;
  final String plasticType;
  final String status;
  final int accumulatedMs;
  final int? endTs;
  final double? fuelLiters;
  final double? averageTempC;

  Batch({
    required this.sessionId,
    required this.startTs,
    required this.originalStartTs,
    required this.startedBy,
    required this.wasteKg,
    required this.plasticType,
    required this.status,
    required this.accumulatedMs,
    this.endTs,
    this.fuelLiters,
    this.averageTempC,
  });

  factory Batch.fromMap(String id, Map<dynamic, dynamic> map) {
    return Batch(
      sessionId: map['sessionId'] ?? id, // fallback ke id jika sessionId missing
      startTs: map['startTs'] ?? 0,
      originalStartTs: map['originalStartTs'] ?? 0,
      startedBy: map['startedBy'] ?? 'unknown',
      wasteKg: (map['wasteKg'] ?? 0.0).toDouble(),
      plasticType: map['plasticType'] ?? '',
      status: map['status'] ?? 'completed',
      accumulatedMs: map['accumulatedMs'] ?? 0,
      endTs: map['endTs'],
      fuelLiters: (map['fuelLiters'] as num?)?.toDouble(),
      averageTempC: (map['averageTempC'] as num?)?.toDouble(),
    );
  }
}
