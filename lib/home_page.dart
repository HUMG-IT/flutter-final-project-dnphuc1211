import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'login_page.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Công việc';
  DateTime? _selectedDueDate;
  String _searchText = '';

  late final TabController _tabController;

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Hàm Đăng xuất
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

  // Hàm chọn ngày giờ hết hạn
  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
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

  // Dialog thêm Task mới
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
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ),
                      )
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

  // Dialog sửa Task
  Future<void> _showEditTaskDialog(QueryDocumentSnapshot task) async {
    final taskId = task.id;
    final currentDone = task['isDone'] ?? false;
    
    // Điền sẵn dữ liệu cũ vào các ô nhập
    _titleController.text = task['title'] ?? '';
    _descriptionController.text = task['description'] ?? '';
    _selectedCategory = task['category'] ?? 'Công việc';
    final dueTimestamp = task['dueDate'] as Timestamp?;
    final oldDueDate = dueTimestamp?.toDate();
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
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ),
                      )
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
                // Kiểm tra xem dueDate có thay đổi không
                final newDueDate = _selectedDueDate;
                final dueDateChanged = oldDueDate != newDueDate;
                
                await _saveTask(taskId, currentDone, dueDateChanged: dueDateChanged);
              },
              child: const Text("Cập nhật"),
            ),
          ],
        );
      },
    );
  }

  // Lưu Task mới hoặc cập nhật
  Future<void> _saveTask(
    String? docId,
    bool currentIsDone, {
    bool dueDateChanged = false,
  }) async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isEmpty) {
      if (!mounted) return;
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
        // Thêm mới
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
      
      // Đặt lịch thông báo nếu có hạn
      // Nếu là cập nhật và dueDate thay đổi, hoặc là thêm mới, thì cập nhật notification
      if (_selectedDueDate != null && (docId == null || dueDateChanged)) {
        final notificationService = context.read<NotificationService>();
        await notificationService.scheduleDueDateNotification(
          id: id.hashCode,
          title: "Nhắc nhở: $title",
          body: _selectedCategory,
          dueDate: _selectedDueDate!,
        );
      }

      _titleController.clear();
      _descriptionController.clear();
      _selectedCategory = 'Công việc';
      _selectedDueDate = null;

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
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

  // Lọc theo thời gian
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
          title: Text("Xin chào, ${user?.email?.split('@')[0]}"),
          actions: [
            // Nút test thông báo
            IconButton(
              tooltip: "Test thông báo",
              onPressed: () async {
                final notificationService = context.read<NotificationService>();
                await notificationService.showInstantNotification(
                  id: 999,
                  title: "Test thông báo",
                  body: "Thông báo test hoạt động bình thường!",
                );
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
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
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
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('userId', isEqualTo: user?.uid)
                    .orderBy('dueDate', descending: false)
                    .snapshots(),
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

                  final filtered = docs.where((d) {
                    final title = (d['title'] ?? '').toString();
                    final dueTs = d['dueDate'] as Timestamp?;
                    final dueDate = dueTs?.toDate();
                    final matchSearch =
                        title.toLowerCase().contains(_searchText.toLowerCase());
                    final matchTime =
                        _matchFilter(dueDate, _tabController.index);
                    return matchSearch && matchTime;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("Không tìm thấy kết quả."));
                  }

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      final docId = task.id;
                      final title = task['title'] ?? '';
                      final description = task['description'] ?? '';
                      final category = task['category'] ?? 'Khác';
                      final isDone = task['isDone'] ?? false;
                      final dueDate =
                          (task['dueDate'] as Timestamp?)?.toDate();

                      final color =
                          _categoryColors[category] ?? Colors.blueGrey;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withValues(alpha: 0.08),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showEditTaskDialog(task),
                          onLongPress: () => _showEditTaskDialog(task),
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
                                      onChanged: (_) =>
                                          _toggleTask(docId, isDone),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (description.isNotEmpty)
                                            Text(
                                              description,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
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
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) =>
                                                  AlertDialog(
                                                title:
                                                    const Text("Xác nhận xóa"),
                                                content: const Text(
                                                    "Bạn có chắc muốn xóa không?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text("Hủy"),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
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
                                    Icon(Icons.schedule,
                                        size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      dueDate == null
                                          ? "Chưa đặt hạn"
                                          : DateFormat('dd/MM/yyyy HH:mm')
                                              .format(dueDate),
                                      style: TextStyle(
                                          color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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