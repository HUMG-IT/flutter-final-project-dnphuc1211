import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'firebase_options.dart';
import 'login_page.dart';

// Provider đổi theme
class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme() {
    themeMode =
        themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

// Service cấu hình và hẹn giờ thông báo cục bộ
class NotificationService {
  final FlutterLocalNotificationsPlugin plugin;
  static const String _channelId = 'task_channel';
  static const String _channelName = 'Task Reminders';
  static const String _channelDescription = 'Nhắc nhở công việc đến hạn';

  NotificationService(this.plugin);

  Future<void> init() async {
    // Tạo Android Notification Channel với importance.max và priority.high
    // Để thông báo có thể bật sáng màn hình và kêu to
    if (Platform.isAndroid) {
      final androidImplementation = plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Tạo channel với cấu hình cao nhất
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }
    }

    // Khởi tạo plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await plugin.initialize(initSettings);

    // Yêu cầu quyền thông báo cho Android 13+ (API 33+)
    if (Platform.isAndroid) {
      final androidImplementation = plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    }
  }

  // Hàm hẹn giờ thông báo với logic "chắc chắn chạy"
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
  }) async {
    // Kiểm tra nếu quá hạn thì bỏ qua
    if (dueDate.isBefore(DateTime.now())) {
      return;
    }

    // Chuyển đổi dueDate sang múi giờ địa phương
    final scheduledDate = tz.TZDateTime.from(dueDate, tz.local);

    // Cấu hình notification details với channel đã tạo
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Xin quyền exact alarms trước khi hẹn giờ
    if (Platform.isAndroid) {
      final androidImplementation = plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    }

    // Thử dùng exact alarm trước (chính xác tuyệt đối)
    try {
      await plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Nếu bị lỗi (thiếu quyền hoặc lỗi khác), fallback ngay lập tức
      // sang chế độ inexact (không cần quyền đặc biệt, sai số 1-2 phút nhưng chắc chắn sẽ hiện)
      try {
        await plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (fallbackError) {
        // Nếu cả inexact cũng lỗi, thử dùng chế độ mặc định (chắc chắn nhất)
        await plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  // Hàm hẹn giờ thông báo theo dueDate (giữ lại để tương thích với code cũ)
  Future<void> scheduleDueDateNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dueDate,
  }) async {
    await scheduleNotification(
      id: id,
      title: title,
      body: body,
      dueDate: dueDate,
    );
  }

  // Hàm test: Hiển thị thông báo ngay lập tức để kiểm tra
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await plugin.show(id, title, body, details);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo notification
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  final notificationService = NotificationService(notificationsPlugin);
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        // InputDecorationTheme: Ô nhập liệu trong Dark Mode
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[300]),
          hintStyle: TextStyle(color: Colors.grey[500]),
        ),
        // TextTheme: Màu chữ tự động sáng trong Dark Mode
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.white60),
          titleLarge: TextStyle(color: Colors.white),
          titleMedium: TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.white70),
          headlineLarge: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
          headlineSmall: TextStyle(color: Colors.white),
        ),
        // AppBarTheme: Màu chữ/icon tự động trắng trong Dark Mode
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        // CardTheme: Màu nền Card tối trong Dark Mode
        cardTheme: CardThemeData(
          color: Colors.grey[850],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}