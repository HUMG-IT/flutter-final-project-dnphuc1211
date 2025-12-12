import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/models/task_model.dart';

void main() {
  group('TaskModel Tests', () {
    test('fromMap - Chuyển đổi Map thành TaskModel đúng cách', () {
      // Arrange: Tạo Map giống như dữ liệu từ Firestore
      final map = {
        'title': 'Test Task',
        'description': 'Mô tả công việc test',
        'category': 'Công việc',
        'isDone': false,
        'dueDate': Timestamp.fromDate(DateTime(2024, 12, 25, 10, 30)),
        'userId': 'user123',
        'createdAt': Timestamp.fromDate(DateTime(2024, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2024, 1, 2)),
      };
      const taskId = 'task123';

      // Act: Gọi fromMap
      final task = TaskModel.fromMap(map, taskId);

      // Assert: Kiểm tra các field
      expect(task.id, equals(taskId));
      expect(task.title, equals('Test Task'));
      expect(task.description, equals('Mô tả công việc test'));
      expect(task.category, equals('Công việc'));
      expect(task.isDone, equals(false));
      expect(task.userId, equals('user123'));
      expect(task.dueDate, isNotNull);
      expect(task.dueDate?.year, equals(2024));
      expect(task.dueDate?.month, equals(12));
      expect(task.dueDate?.day, equals(25));
    });

    test('fromMap - Xử lý dữ liệu null/thiếu đúng cách', () {
      // Arrange: Map với một số field null hoặc thiếu
      final map = {
        'title': 'Task không đầy đủ',
        // description thiếu
        // category thiếu
        // isDone thiếu
        // dueDate null
        'userId': 'user456',
      };
      const taskId = 'task456';

      // Act
      final task = TaskModel.fromMap(map, taskId);

      // Assert: Kiểm tra giá trị mặc định
      expect(task.id, equals(taskId));
      expect(task.title, equals('Task không đầy đủ'));
      expect(task.description, equals('')); // Giá trị mặc định
      expect(task.category, equals('Khác')); // Giá trị mặc định
      expect(task.isDone, equals(false)); // Giá trị mặc định
      expect(task.dueDate, isNull);
      expect(task.userId, equals('user456'));
    });

    test('toMap - Chuyển đổi TaskModel thành Map đúng cách', () {
      // Arrange: Tạo TaskModel
      final task = TaskModel(
        id: 'task789',
        title: 'Task để test toMap',
        description: 'Mô tả',
        category: 'Học tập',
        isDone: true,
        dueDate: DateTime(2024, 6, 15, 14, 0),
        userId: 'user789',
      );

      // Act: Gọi toMap
      final map = task.toMap();

      // Assert: Kiểm tra Map
      expect(map['title'], equals('Task để test toMap'));
      expect(map['description'], equals('Mô tả'));
      expect(map['category'], equals('Học tập'));
      expect(map['isDone'], equals(true));
      expect(map['dueDate'], equals(DateTime(2024, 6, 15, 14, 0)));
      expect(map['userId'], equals('user789'));
      // createdAt và updatedAt không có trong toMap (dùng serverTimestamp)
      expect(map.containsKey('createdAt'), isFalse);
      expect(map.containsKey('updatedAt'), isFalse);
    });

    test('copyWith - Tạo bản sao với field được thay đổi', () {
      // Arrange: TaskModel ban đầu
      final original = TaskModel(
        id: 'task1',
        title: 'Task gốc',
        description: 'Mô tả gốc',
        category: 'Công việc',
        isDone: false,
        userId: 'user1',
      );

      // Act: Tạo bản sao với một số field thay đổi
      final copied = original.copyWith(
        title: 'Task đã sửa',
        isDone: true,
      );

      // Assert: Kiểm tra field thay đổi và field giữ nguyên
      expect(copied.id, equals(original.id)); // Giữ nguyên
      expect(copied.title, equals('Task đã sửa')); // Đã thay đổi
      expect(copied.description, equals(original.description)); // Giữ nguyên
      expect(copied.category, equals(original.category)); // Giữ nguyên
      expect(copied.isDone, equals(true)); // Đã thay đổi
      expect(copied.userId, equals(original.userId)); // Giữ nguyên
    });

    test('copyWith - Tạo bản sao không thay đổi gì', () {
      // Arrange
      final original = TaskModel(
        id: 'task2',
        title: 'Task gốc',
        description: 'Mô tả',
        category: 'Cá nhân',
        isDone: false,
        userId: 'user2',
      );

      // Act: copyWith không có tham số
      final copied = original.copyWith();

      // Assert: Tất cả field giữ nguyên
      expect(copied.id, equals(original.id));
      expect(copied.title, equals(original.title));
      expect(copied.description, equals(original.description));
      expect(copied.category, equals(original.category));
      expect(copied.isDone, equals(original.isDone));
      expect(copied.userId, equals(original.userId));
    });

    test('Round-trip: fromMap -> toMap -> fromMap', () {
      // Arrange: Tạo Map ban đầu
      final originalMap = {
        'title': 'Task round-trip',
        'description': 'Mô tả round-trip',
        'category': 'Gia đình',
        'isDone': true,
        'dueDate': Timestamp.fromDate(DateTime(2024, 3, 20)),
        'userId': 'user_roundtrip',
      };
      const taskId = 'task_roundtrip';

      // Act: fromMap -> toMap -> fromMap
      final task1 = TaskModel.fromMap(originalMap, taskId);
      final map2 = task1.toMap();
      // Lưu ý: toMap không có createdAt/updatedAt, nên cần thêm lại
      map2['dueDate'] = originalMap['dueDate'];
      final task2 = TaskModel.fromMap(map2, taskId);

      // Assert: Kiểm tra dữ liệu giống nhau
      expect(task2.id, equals(task1.id));
      expect(task2.title, equals(task1.title));
      expect(task2.description, equals(task1.description));
      expect(task2.category, equals(task1.category));
      expect(task2.isDone, equals(task1.isDone));
      expect(task2.userId, equals(task1.userId));
    });
  });
}

