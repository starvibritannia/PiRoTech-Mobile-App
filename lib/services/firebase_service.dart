// lib/services/firebase_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../models/batch_model.dart';
import '../utils/session_id_generator.dart'; // Import generator

class FirebaseService {
  // Singleton instance
  static final FirebaseService instance = FirebaseService._internal();
  factory FirebaseService() => instance;
  FirebaseService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // --- Tambahan baru untuk sistem Batch (Sinkron Web) ---
  Stream<Batch?> streamRunningBatch() {
    return _db.ref('batches').onValue.map((event) {
      if (event.snapshot.exists) {
        final allBatches = event.snapshot.value as Map<dynamic, dynamic>;
        
        // Cari batch yang sedang 'running' atau 'paused'
        for (var key in allBatches.keys) {
          final b = allBatches[key] as Map<dynamic, dynamic>;
          if (b['status'] == 'running' || b['status'] == 'paused') {
            return Batch.fromMap(key.toString(), b);
          }
        }
      }
      return null; // Tidak ada batch yang aktif
    });
  }
  
  // --- Fungsi Statistik (Sinkron Web) ---
  Stream<List<Batch>> streamBatchHistory() {
    return _db.ref('batches')
        .orderByChild('status')
        .equalTo('completed')
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((e) => Batch.fromMap(e.key.toString(), e.value as Map<dynamic, dynamic>)).toList();
      }
      return [];
    });
  }

  // --- Fungsi Kontrol Batch (Sinkron Web) ---
  
  Future<void> startFirebaseBatch(double wasteKg, String plasticType, String username) async {
    final sessionId = await SessionIdGenerator.generateSessionId(username);
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.ref('batches/$sessionId').set({
      'sessionId': sessionId,
      'startTs': now,
      'originalStartTs': now,
      'startedBy': username,
      'wasteKg': wasteKg,
      'plasticType': plasticType,
      'status': 'running',
      'accumulatedMs': 0,
    });
  }

  Future<void> pauseFirebaseBatch(String batchId, int accumulatedMs) async {
    await _db.ref('batches/$batchId').update({
      'status': 'paused',
      'accumulatedMs': accumulatedMs,
      'lastPausedAt': ServerValue.timestamp,
    });
  }

  Future<void> resumeFirebaseBatch(String batchId) async {
    await _db.ref('batches/$batchId').update({
      'status': 'running',
      'lastStartedAt': ServerValue.timestamp,
    });
  }

  Future<void> stopFirebaseBatch(String batchId, int accumulatedMs, double wasteKg, String plasticType, int startTs) async {
    // 1. Hitung rentang untuk query efisien (Sesuai panduan Log Activity)
    final startId = SessionIdGenerator.generatePushIdFromTimestamp(startTs);
    final endId = SessionIdGenerator.generatePushIdFromTimestamp(DateTime.now().millisecondsSinceEpoch);

    // 2. Query sensor_data efisien
    final query = _db.ref('sensor_data').orderByKey().startAt(startId).endAt(endId);
    final snapshot = await query.get();

    double totalTemp = 0.0;
    double maxTemp = 0.0;
    int count = 0;

    if (snapshot.exists) {
      final readings = Map<dynamic, dynamic>.from(snapshot.value as Map);
      readings.forEach((key, value) {
        final data = Map<String, dynamic>.from(value as Map);
        final temp = (data['temperature_c'] ?? 0.0).toDouble();
        totalTemp += temp;
        if (temp > maxTemp) maxTemp = temp;
        count++;
      });
    }

    double avgTemp = count > 0 ? totalTemp / count : 0.0;

    // 3. Estimasi BBM (Sesuai panduan)
    // Yield rata-rata 0.5
    double finalResultKg = (wasteKg * 0.5) / 0.815; 

    // 4. Update status batch
    await _db.ref('batches/$batchId').update({
      'status': 'completed',
      'endTs': DateTime.now().millisecondsSinceEpoch,
      'accumulatedMs': accumulatedMs,
      'fuelLiters': finalResultKg,
      'averageTempC': double.parse(avgTemp.toStringAsFixed(1)),
    });
    
    // 5. Simpan ke log_activity (Format Sesuai Panduan)
    final duration = Duration(milliseconds: accumulatedMs);
    String formattedDuration = "${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}";

    await _db.ref('log_activity/$batchId').set({
      'tanggal': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      'startTs': startTs,
      'endTs': DateTime.now().millisecondsSinceEpoch,
      'berat_kg': wasteKg,
      'jenis_plastik': plasticType.toUpperCase(),
      'bbm_liter': double.parse(finalResultKg.toStringAsFixed(2)),
      'durasi': formattedDuration,
      'suhu_avg': double.parse(avgTemp.toStringAsFixed(1)),
      'suhu_max': double.parse(maxTemp.toStringAsFixed(1)),
    });
  }

  // 1. Fungsi untuk MENDENGARKAN data sensor (Suhu & Tekanan) secara LIVE
  Stream<MonitoringData?> streamMonitoring() {
    return _db.ref('monitoring').onValue.map((event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return MonitoringData.fromMap(data);
      }
      return null;
    });
  }

  // 2. Fungsi untuk MENDENGARKAN status Buzzer/Alarm
  Stream<bool> streamBuzzer() {
    return _db.ref('control/buzzer').onValue.map((event) {
      if (event.snapshot.exists) {
        return event.snapshot.value as bool;
      }
      return false;
    });
  }

  // 3. Fungsi untuk MENEKAN TOMBOL/MENGUBAH status Buzzer ke Firebase
  Future<void> setBuzzerState(bool isOn) async {
    try {
      await _db.ref('control/buzzer').set(isOn);
      // Opsional: Catat log siapa yang mematikan buzzer ke 'pirotech/controlLog'
    } catch (e) {
      print("Error setting buzzer: $e");
    }
  }
}