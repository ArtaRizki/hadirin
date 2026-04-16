import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  // Singleton pattern agar tidak membuat banyak instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Inisialisasi Database Timezone
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 2. Pengaturan Icon Notifikasi Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. Pengaturan iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // 4. Meminta Izin Notifikasi (Android 13+)
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // Fungsi untuk Menjadwalkan Notifikasi Harian
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Jika waktu sudah lewat hari ini, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hadirin_reminders',
          'Pengingat Absensi',
          channelDescription: 'Pengingat rutin absen pagi dan sore',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Ulangi setiap hari
    );
  }

  // Fungsi untuk Membatalkan Semua Notifikasi
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  // Fungsi untuk Memunculkan Notifikasi
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'hadirin_absen_channel', // ID Channel
          'Notifikasi Absensi', // Nama Channel
          channelDescription: 'Pemberitahuan saat berhasil atau gagal absen',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  // Fungsi Helper untuk Setup Pengingat Rutin (Pagi & Sore)
  Future<void> setupReminders({
    bool showMasuk = true,
    bool showPulang = true,
  }) async {
    // Batalkan dulu semua agar tidak duplikat
    await cancelAll();

    // 1. Pengingat Pagi (07:30)
    if (showMasuk) {
      await scheduleDailyNotification(
        id: 101,
        title: "Selamat Pagi! ✨",
        body: "Awali hari Anda dengan semangat. Jangan lupa absen masuk ya!",
        hour: 7,
        minute: 30,
      );
    }

    // 2. Pengingat Sore (16:30)
    if (showPulang) {
      await scheduleDailyNotification(
        id: 102,
        title: "Kerja Bagus Hari Ini! 🌟",
        body:
            "Jangan lupa absen pulang sebelum beristirahat. Hati-hati di jalan pulang!",
        hour: 16,
        minute: 30,
      );
    }
  }
}
