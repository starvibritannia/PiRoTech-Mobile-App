// lib/services/firebase_service.dart

import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart'; // Import file model yang kita buat tadi

class FirebaseService {
  // Inisialisasi Firebase Realtime Database
  final FirebaseDatabase _db = FirebaseDatabase.instance;

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