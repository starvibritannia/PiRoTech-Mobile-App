// lib/services/firebase_service.dart

import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';
import '../models/batch_model.dart'; // Import model baru

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
  
  Future<void> startFirebaseBatch(double wasteKg, String plasticType, String userId) async {
    final ref = _db.ref('batches').push();
    await ref.set({
      'originalStartTs': ServerValue.timestamp,
      'status': 'running',
      'wasteKg': wasteKg,
      'plasticType': plasticType,
      'userId': userId,
      'accumulatedMs': 0,
      'lastStartedAt': ServerValue.timestamp,
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

  Future<void> stopFirebaseBatch(String batchId, int accumulatedMs, double resultKg, double wasteKg, String plasticType, int startTs) async {
    await _db.ref('batches/$batchId').update({
      'status': 'completed',
      'endedAt': ServerValue.timestamp,
      'accumulatedMs': accumulatedMs,
    });
    
    // Simpan ke log_activity juga untuk history
    await _db.ref('log_activity').push().set({
      'tanggal': DateTime.now().toString(),
      'jenis_plastik': plasticType,
      'berat_kg': wasteKg,
      'hasil_kg': resultKg,
      'durasi_ms': accumulatedMs,
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