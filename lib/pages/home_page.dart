import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/theme_provider.dart';
import 'login_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Lấy user mới nhất mỗi lần build
  User? get user => FirebaseAuth.instance.currentUser;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Công việc';
  DateTime? _selectedDueDate;
  String _searchText = '';

  late final TabController _tabController;
  late final Stream<QuerySnapshot> _tasksStream;

  final List<String> _categories = [
    'Công việc',
    'Cá nhân',
    'Gia đình',
    'Học tập',
    'Khác',
  ];

  final Map<String, Color> _categoryColors = {
    'Công việc': Colors.indigo,
    'Cá nhân': Colors.teal,
    'Gia đình': Colors.orange,
    'Học tập': Colors.purple,
    'Khác': Colors.blueGrey,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));

    // QUAN TRỌNG: Chỉ lọc theo UserID, KHÔNG sắp xếp ở đây để tránh lỗi ẩn task
    // (Nếu sort bằng dueDate mà task đó dueDate=null thì sẽ bị ẩn luôn)
    _tasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: user?.uid)
        .snapshots();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDueDate ?? now),
    );
    if (pickedTime == null) return;

    setState(() {
      _selectedDueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _openTaskDialog() async {
    _titleController.clear();
    _descriptionController.clear();
    _selectedCategory = 'Công việc';
    _selectedDueDate = null;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Thêm công việc"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Tiêu đề"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Nội dung"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                  decoration: const InputDecoration(labelText: "Danh mục"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDueDate == null
                            ? "Chưa chọn hạn"
                            : "Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedDueDate!)}",
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDueDateTime,
                      child: const Text("Chọn hạn"),
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveTask(null, false);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditTaskDialog(QueryDocumentSnapshot taskDoc) async {
    // Lấy dữ liệu an toàn
    final data = taskDoc.data() as Map<String, dynamic>;
    final title = data['title'] ?? '';
    final description = data['description'] ?? '';
    final category = data['category'] ?? 'Công việc';
    final isDone = data['isDone'] ?? false;
    
    Timestamp? dueTs = data['dueDate'];
    DateTime? oldDueDate = dueTs?.toDate();

    _titleController.text = title;
    _descriptionController.text = description;
    _selectedCategory = category;
    _selectedDueDate = oldDueDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Sửa công việc"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Tiêu đề"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Nội dung"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                  decoration: const InputDecoration(labelText: "Danh mục"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDueDate == null
                            ? "Chưa chọn hạn"
                            : "Hạn: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedDueDate!)}",
                      ),
                    ),
                    TextButton(
                      onPressed: _pickDueDateTime,
                      child: const Text("Chọn hạn"),
                    ),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newDueDate = _selectedDueDate;
                final dueDateChanged = oldDueDate != newDueDate;
                await _saveTask(taskDoc.id, isDone, dueDateChanged: dueDateChanged);
              },
              child: const Text("Cập nhật"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTask(
    String? docId,
    bool currentIsDone, {
    bool dueDateChanged = false,
  }) async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tiêu đề không được để trống")),
      );
      return;
    }

    final data = {
      'title': title,
      'description': description,
      'category': _selectedCategory,
      'dueDate': _selectedDueDate,
      'isDone': docId == null ? false : currentIsDone,
      'userId': user?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      String id = docId ?? '';
      if (docId == null) {
        // Thêm mới: Thêm createdAt để sắp xếp
        final ref = await FirebaseFirestore.instance.collection('tasks').add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
        id = ref.id;
      } else {
        // Cập nhật
        await FirebaseFirestore.instance.collection('tasks').doc(docId).update({
          ...data,
        });
        id = docId;
      }

      if (!mounted) return;

      // Đặt lịch thông báo
      if (_selectedDueDate != null && (docId == null || dueDateChanged)) {
        // Kiểm tra xem NotificationService có trong context không
        try {
            final notificationService = context.read<NotificationService>();
            await notificationService.scheduleDueDateNotification(
              id: id.hashCode,
              title: "Nhắc nhở: $title",
              body: _selectedCategory,
              dueDate: _selectedDueDate!,
            );
        } catch(e) {
            debugPrint("Notification Error: $e");
        }
      }

      _titleController.clear();
      _descriptionController.clear();
      _selectedCategory = 'Công việc';
      _selectedDueDate = null;

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi lưu dữ liệu: $e")),
      );
    }
  }

  Future<void> _deleteTask(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(docId).delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi xóa: $e")),
      );
    }
  }

  Future<void> _toggleTask(String docId, bool isDone) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(docId).update({
        'isDone': !isDone,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi cập nhật: $e")),
      );
    }
  }

  Widget _buildTaskCard(QueryDocumentSnapshot taskDoc) {
    // Chuyển đổi dữ liệu an toàn
    final data = taskDoc.data() as Map<String, dynamic>;
    final docId = taskDoc.id;
    final title = data['title'] ?? '(Không tiêu đề)';
    final description = data['description'] ?? '';
    final category = data['category'] ?? 'Khác';
    final isDone = data['isDone'] ?? false;
    
    Timestamp? dueTs = data['dueDate'];
    DateTime? dueDate = dueTs?.toDate();

    final color = _categoryColors[category] ?? Colors.blueGrey;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditTaskDialog(taskDoc),
        onLongPress: () => _showEditTaskDialog(taskDoc),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isDone,
                    activeColor: color,
                    onChanged: (_) => _toggleTask(docId, isDone),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDone
                                ? Colors.green
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (description.toString().isNotEmpty)
                          Text(
                            description,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Xác nhận xóa"),
                              content: const Text("Bạn có chắc muốn xóa không?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Hủy"),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text("Xóa"),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _deleteTask(docId);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dueDate == null
                        ? "Chưa đặt hạn"
                        : DateFormat('dd/MM/yyyy HH:mm').format(dueDate),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchFilter(DateTime? due, int tabIndex) {
    if (tabIndex == 0) return true; // Tất cả
    if (due == null) return false;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final endOfWeek = startOfDay.add(Duration(days: 7 - now.weekday));
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    if (tabIndex == 1) {
      return due.isAfter(startOfDay) && due.isBefore(endOfDay);
    } else if (tabIndex == 2) {
      return due.isAfter(startOfDay) && due.isBefore(endOfWeek);
    } else {
      return due.isAfter(startOfDay) && due.isBefore(endOfMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Xin chào, ${user?.displayName ?? user?.email?.split('@')[0] ?? 'Người dùng'}"),
          actions: [
            IconButton(
              tooltip: "Test thông báo",
              onPressed: () async {
                try {
                    final notificationService = context.read<NotificationService>();
                    await notificationService.showInstantNotification(
                    id: 999,
                    title: "Test thông báo",
                    body: "Thông báo test hoạt động bình thường!",
                    );
                } catch(e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi Service Thông báo")));
                }
              },
              icon: const Icon(Icons.notifications),
            ),
            IconButton(
              tooltip: "Chuyển theme",
              onPressed: themeProvider.toggleTheme,
              icon: Icon(themeProvider.themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode),
            ),
            PopupMenuButton<String>(
              icon: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (user?.email ?? 'U').split('@')[0][0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onSelected: (value) async {
                if (value == 'profile') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                  await FirebaseAuth.instance.currentUser?.reload();
                  if (mounted) setState(() {});
                } else if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('Thông tin cá nhân'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Tất cả"),
              Tab(text: "Hôm nay"),
              Tab(text: "Tuần này"),
              Tab(text: "Tháng này"),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Tìm kiếm theo tiêu đề...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (val) => setState(() => _searchText = val),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _tasksStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Có lỗi xảy ra!"));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                        child: Text("Chưa có công việc nào. Thêm đi bạn!"));
                  }

                  // Lọc và Sắp xếp Client-side (Mới nhất lên đầu)
                  final filtered = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '').toString();
                    final dueTs = data['dueDate'] as Timestamp?;
                    final dueDate = dueTs?.toDate();
                    final matchSearch =
                        title.toLowerCase().contains(_searchText.toLowerCase());
                    final matchTime =
                        _matchFilter(dueDate, _tabController.index);
                    return matchSearch && matchTime;
                  }).toList();

                  // Sắp xếp: createdAt giảm dần (Mới nhất lên đầu)
                  // Nếu không có createdAt thì đẩy xuống cuối
                  filtered.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;
                      final tsA = dataA['createdAt'] as Timestamp?;
                      final tsB = dataB['createdAt'] as Timestamp?;
                      
                      if (tsA == null) return 1;
                      if (tsB == null) return -1;
                      return tsB.compareTo(tsA);
                  });

                  if (filtered.isEmpty) {
                    return const Center(child: Text("Không tìm thấy kết quả."));
                  }

                  final unfinishedTasks = filtered.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return !(data['isDone'] ?? false);
                  }).toList();

                  final completedTasks = filtered.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['isDone'] ?? false);
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: unfinishedTasks.length +
                        (completedTasks.isNotEmpty ? 1 : 0) +
                        completedTasks.length,
                    itemBuilder: (context, index) {
                      if (index < unfinishedTasks.length) {
                        return _buildTaskCard(unfinishedTasks[index]);
                      }

                      if (index == unfinishedTasks.length &&
                          completedTasks.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  "Đã hoàn thành (${completedTasks.length})",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  thickness: 1,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final completedIndex =
                          index - unfinishedTasks.length - 1;
                      return Opacity(
                        opacity: 0.7,
                        child: _buildTaskCard(completedTasks[completedIndex]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openTaskDialog(),
          icon: const Icon(Icons.add),
          label: const Text("Thêm"),
        ),
      ),
    );
  }
}