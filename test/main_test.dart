import 'package:flutter_project/services/notification_service.dart';
import 'package:flutter_project/services/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_project/main.dart'; 

void main() {
  testWidgets('Kiểm tra App khởi động thành công', (WidgetTester tester) async {
    // Tạo plugin giả để truyền vào Service
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          // Truyền plugin vào đây để khớp với constructor
          Provider(create: (_) => NotificationService(flutterLocalNotificationsPlugin)),
        ],
        child: const MyApp(),
      ),
    );

    // Kiểm tra xem widget MyApp có xuất hiện không
    expect(find.byType(MyApp), findsOneWidget);
  });
}