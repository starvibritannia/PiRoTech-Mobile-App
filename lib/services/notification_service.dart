import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _hasPermission = false;

  Future<void> init() async {
    // Pengaturan untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // Pengaturan untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notif tap (opsional)
      },
    );

    // Minta izin notifikasi untuk Android 13+
    await _requestPermission();
  }

  /// Minta izin notifikasi (Android 13+ / API 33+)
  Future<void> _requestPermission() async {
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      //Ini akan memunculkan dialog izin di Android 13+
      final granted = await androidPlugin.requestNotificationsPermission();
      _hasPermission = granted ?? false;
      debugPrint('[NotificationService] Permission granted: $_hasPermission');
    } else {
      // Bukan Android, anggap punya izin
      _hasPermission = true;
    }
  }

  // Fungsi untuk memunculkan notifikasi pop-up
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required bool isCritical,
  }) async {
    // Kalau izin belum dikasih, skip
    if (!_hasPermission) {
      debugPrint('[NotificationService] Izin belum diberikan, skip notifikasi.');
      return;
    }

    // Pengaturan bentuk notifikasi di Android
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'pirotech_alerts',
      'Peringatan Suhu PiRoTech',
      channelDescription: 'Saluran untuk peringatan suhu reaktor',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'PiRoTech Alert',
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
