// lib/models/batch_model.dart

class Batch {
  final String id;
  final int startTs;
  final int? originalStartTs;
  final double wasteKg;
  final String plasticType;
  final String status;
  final int accumulatedMs;
  final int? pausedAt;
  final int? endTs;
  final double? fuelLiters;

  Batch({
    required this.id,
    required this.startTs,
    this.originalStartTs,
    required this.wasteKg,
    required this.plasticType,
    required this.status,
    required this.accumulatedMs,
    this.pausedAt,
    this.endTs,
    this.fuelLiters,
  });

  factory Batch.fromMap(String id, Map<dynamic, dynamic> map) {
    return Batch(
      id: id,
      startTs: map['startTs'] ?? 0,
      originalStartTs: map['originalStartTs'],
      wasteKg: (map['wasteKg'] ?? 0.0).toDouble(),
      plasticType: map['plasticType'] ?? '',
      status: map['status'] ?? 'completed',
      accumulatedMs: map['accumulatedMs'] ?? 0,
      pausedAt: map['pausedAt'],
      endTs: map['endTs'],
      fuelLiters: (map['fuelLiters'] as num?)?.toDouble(),
    );
  }
}
