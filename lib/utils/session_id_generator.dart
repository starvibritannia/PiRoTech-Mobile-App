import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

class SessionIdGenerator {
  static String generatePushIdFromTimestamp(int timestampMs) {
    const pushChars = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
    int t = timestampMs;
    List<String> timeStampChars = List.filled(8, '');
    for (int i = 7; i >= 0; i--) {
      timeStampChars[i] = pushChars[t % 64];
      t = (t / 64).floor();
    }
    return timeStampChars.join('') + '000000000000';
  }

  static Future<String> generateSessionId(String username) async {
    final now = DateTime.now();
    // Gunakan zona waktu WIB (UTC+7). 
    // Mengingat DateTime.now() di Flutter tergantung perangkat,
    // asumsikan perangkat user sudah diset ke WIB.
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final timeStr = DateFormat('HHmm').format(now);
    
    // 1. Query batches/ untuk hari ini
    final ref = FirebaseDatabase.instance.ref('batches');
    final snapshot = await ref.get();
    
    int count = 0;
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final batch = value as Map<dynamic, dynamic>;
        // Asumsi struktur data baru punya startTs
        if (batch['startTs'] != null) {
          final batchDate = DateFormat('yyyyMMdd').format(
            DateTime.fromMillisecondsSinceEpoch(batch['startTs']),
          );
          if (batchDate == dateStr) {
            count++;
          }
        }
      });
    }
    
    // 2. SEQ 3 digit
    final seqStr = (count + 1).toString().padLeft(3, '0');
    
    // 3. Bersihkan username
    final cleanUsername = username.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    
    return 'SESI-$dateStr-$timeStr-$seqStr-$cleanUsername';
  }
}
