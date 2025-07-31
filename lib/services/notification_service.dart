import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import '../models/models.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();

  static const String _paymentReminderTaskName = 'paymentReminderTask';

  Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
      macOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for notifications
    await _requestPermissions();

    // Initialize WorkManager for background tasks
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    // Schedule daily payment reminder check
    await _scheduleDailyPaymentCheck();
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _scheduleDailyPaymentCheck() async {
    // Cancel any existing task
    await Workmanager().cancelByUniqueName(_paymentReminderTaskName);

    // Schedule a daily task to check for payment reminders
    await Workmanager().registerPeriodicTask(
      _paymentReminderTaskName,
      _paymentReminderTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 1), // Start checking after 1 minute
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    debugPrint('Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> checkAndSendPaymentReminders() async {
    try {
      final studentsWithDuePayments = await _getStudentsWithDuePayments();

      if (studentsWithDuePayments.isNotEmpty) {
        await _sendPaymentReminderNotification(studentsWithDuePayments);
      }
    } catch (e) {
      debugPrint('Error checking payment reminders: $e');
    }
  }

  Future<List<Student>> _getStudentsWithDuePayments() async {
    final students = await _databaseService.getStudents();
    final studentsWithDuePayments = <Student>[];

    for (final student in students) {
      final shouldPay = await _databaseService.shouldStudentPay(student.id!);
      if (shouldPay) {
        studentsWithDuePayments.add(student);
      }
    }

    return studentsWithDuePayments;
  }

  Future<void> _sendPaymentReminderNotification(List<Student> students) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'payment_reminders',
      'Rappels de paiement',
      channelDescription: 'Notifications pour les paiements d\'étudiants dus',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: iOSPlatformChannelSpecifics,
    );

    String title;
    String body;

    if (students.length == 1) {
      title = 'Rappel de paiement';
      body = '${students.first.name} a un paiement dû aujourd\'hui.';
    } else {
      title = 'Rappels de paiement';
      body = '${students.length} étudiants ont des paiements dus aujourd\'hui.';
    }

    await _flutterLocalNotificationsPlugin.show(
      0, // notification id
      title,
      body,
      platformChannelSpecifics,
      payload: 'payment_reminder',
    );
  }

  Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_notifications',
      'Notifications de test',
      channelDescription:
          'Notifications de test pour vérifier le fonctionnement',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      1, // notification id
      'Test de notification',
      'Les notifications fonctionnent correctement!',
      platformChannelSpecifics,
      payload: 'test',
    );
  }

  Future<void> sendPaymentDueNotification(Student student,
      [Group? group]) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'payment_due_immediate',
      'Paiements dus immédiatement',
      channelDescription:
          'Notifications immédiates quand un étudiant atteint 4 séances',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: iOSPlatformChannelSpecifics,
    );

    final sessionsCount = group?.sessionsPerPayment ?? 4;
    await _flutterLocalNotificationsPlugin.show(
      2, // notification id
      'Paiement dû!',
      '${student.name} a atteint $sessionsCount séances et doit effectuer un paiement.',
      platformChannelSpecifics,
      payload: 'payment_due_${student.id}',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    await Workmanager().cancelAll();
  }
}

// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == NotificationService._paymentReminderTaskName) {
        final notificationService = NotificationService();
        await notificationService.checkAndSendPaymentReminders();
        return Future.value(true);
      }
    } catch (e) {
      debugPrint('Background task error: $e');
    }
    return Future.value(false);
  });
}
