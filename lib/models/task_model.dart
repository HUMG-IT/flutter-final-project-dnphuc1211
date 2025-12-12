import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho một Task trong ứng dụng
/// Có các hàm fromMap, toMap, copyWith để xử lý dữ liệu Firestore
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final bool isDone;
  final DateTime? dueDate;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Constructor
  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.isDone,
    this.dueDate,
    required this.userId,
    this.createdAt,
    this.updatedAt,
  });

  /// Tạo TaskModel từ Map (thường là từ Firestore document)
  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Khác',
      isDone: map['isDone'] ?? false,
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] is Timestamp
              ? (map['dueDate'] as Timestamp).toDate()
              : map['dueDate'] is DateTime
                  ? map['dueDate'] as DateTime
                  : null)
          : null,
      userId: map['userId'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : map['createdAt'] is DateTime
                  ? map['createdAt'] as DateTime
                  : null)
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : map['updatedAt'] is DateTime
                  ? map['updatedAt'] as DateTime
                  : null)
          : null,
    );
  }

  /// Tạo TaskModel từ Firestore DocumentSnapshot
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    return TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Chuyển TaskModel thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'isDone': isDone,
      'dueDate': dueDate,
      'userId': userId,
      // createdAt và updatedAt thường dùng FieldValue.serverTimestamp()
      // nên không cần thêm vào map khi tạo mới
    };
  }

  /// Tạo bản sao của TaskModel với một số field được thay đổi
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? isDone,
    DateTime? dueDate,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, category: $category, isDone: $isDone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.isDone == isDone &&
        other.dueDate == dueDate &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        category.hashCode ^
        isDone.hashCode ^
        dueDate.hashCode ^
        userId.hashCode;
  }
}

