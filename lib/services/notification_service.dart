import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Pengaturan untuk Android (menggunakan ikon aplikasi bawaan '@mipmap/ic_launcher')
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // Pengaturan untuk iOS (opsional, biarkan saja jika kamu fokus ke Android)
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Apa yang terjadi jika notifikasi di-tap?
        // Untuk sekarang biarkan kosong (hanya menutup popup).
      },
    );
  }

  // Fungsi untuk memunculkan notifikasi pop-up
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required bool isCritical,
  }) async {
    // Pengaturan bentuk notifikasi di Android
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'pirotech_alerts', // ID Channel
      'Peringatan Suhu PiRoTech', // Nama Channel (muncul di pengaturan HP)
      channelDescription: 'Saluran untuk peringatan suhu reaktor',
      importance:
          Importance.max, // Penting agar pop-up muncul di atas (heads up)
      priority: Priority.high,
      ticker: 'PiRoTech Alert',
      // Jika suhu kritis, gunakan warna merah dan getaran yang lebih lama
      color: isCritical ? const Color(0xFFD32F2F) : const Color(0xFFF57C00),
      enableVibration: true,
      playSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
