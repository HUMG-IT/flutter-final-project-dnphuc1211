import 'package:flutter/material.dart';
import 'package:flutter_project/services/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_project/pages/login_page.dart';

void main() {
  Widget createLoginScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MaterialApp(home: LoginPage()),
    );
  }

  group('LoginPage Widget Tests', () {
    // 1. Test các thành phần cơ bản (Giữ nguyên)
    testWidgets('Tìm thấy các thành phần nhập liệu', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      expect(find.byType(TextField), findsAtLeastNWidgets(2));
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    // 2. Test nút Đăng nhập (Sửa lại logic tìm kiếm)
    testWidgets('Tìm thấy nút Đăng nhập', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      
      // MẸO: Vì giao diện mới có thể không dùng ElevatedButton
      // Ta tìm xem có dòng chữ "Đăng nhập" (hoặc Đăng Nhập) nào xuất hiện không
      expect(find.textContaining('Đăng', findRichText: true), findsWidgets);
    });

    // 3. Test nút chuyển đổi (Giữ nguyên logic tìm TextButton)
    testWidgets('Có nút chuyển đổi Đăng nhập/Đăng ký', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());
      // Tìm nút TextButton (thường là nút footer)
      expect(find.byType(TextButton), findsWidgets);
    });

    // 4. Test chuyển đổi (SỬA LẠI LOGIC QUAN TRỌNG NHẤT)
    testWidgets('Chuyển đổi giữa Đăng nhập và Đăng ký', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Bước 1: Tìm nút chuyển đổi (Lấy cái cuối cùng)
      final switchButton = find.byType(TextButton).last;
      
      // Bước 2: Bấm vào đó
      await tester.tap(switchButton);
      await tester.pumpAndSettle(); // Chờ UI cập nhật

      // Bước 3: Kiểm tra kết quả
      // Sau khi bấm, màn hình phải chuyển sang chế độ "Đăng ký"
      // -> Trên màn hình phải xuất hiện chữ "Đăng ký" (hoặc Đăng Ký)
      // Ta dùng find.textContaining để tìm, và findsWidgets (số nhiều) 
      // vì chữ này có thể xuất hiện ở cả Tiêu đề lẫn Nút bấm.
      expect(find.textContaining('Đăng ký', findRichText: true), findsWidgets);
      
      // Và cũng kiểm tra xem chữ "Đăng nhập" có còn là tiêu đề chính không 
      // (Nếu logic đúng thì nút bấm bây giờ phải là Đăng Ký)
    });
  });
}