/*

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:task_management_todo/Calendar/Calendar_Screen.dart';
import 'package:task_management_todo/BottomNavScreens/Category_screen.dart';
import 'package:task_management_todo/BottomNavScreens/GraphScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? currentUser;
  late CollectionReference userTasksRef;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;

    userTasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('tasks');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _checkMissedTasks();
  }

  // --- Notifications ---
  Future<void> scheduleDailyTaskNotification(
      String title, DateTime taskDateTime) async {
    final now = DateTime.now();
    DateTime notifyTime = taskDateTime;

    if (notifyTime.isBefore(now)) {
      notifyTime = notifyTime.add(const Duration(days: 1));
    }

    int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    Future.delayed(notifyTime.difference(now), () async {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'Task Reminder',
        title,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            channelDescription: 'Reminders for your tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );

      scheduleDailyTaskNotification(title, notifyTime.add(const Duration(days: 1)));
    });
  }

  // --- Missed Tasks ---
  Future<void> _checkMissedTasks() async {
    final snapshot =
        await userTasksRef.where('status', isEqualTo: 'future').get();

    for (var doc in snapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final taskDate = (data['date'] as Timestamp).toDate();
      if (taskDate.isBefore(DateTime.now())) {
        await doc.reference.update({'status': 'missed'});

        await flutterLocalNotificationsPlugin.show(
          doc.hashCode,
          'Task Missed!',
          data['title'],
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'missed_channel',
              'Missed Tasks',
              channelDescription: 'Tasks you missed',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final username =
        currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.12),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          flexibleSpace: Padding(
            padding: EdgeInsets.only(
                top: height * 0.05, left: width * 0.05, right: width * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Hi $username",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 6),
                      child: Text(
                        "to-do",
                        style: GoogleFonts.poppins(
                            fontSize: width * 0.03,
                            color: Colors.black,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 26),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/onboarding', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              _buildSearchBar(width, height),

              // Filter Chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildChip("All Task", true),
                    _buildChip("Work", false),
                    _buildChip("Personal", false),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Future Section
              _buildTaskSection("Future", "future"),

              const SizedBox(height: 20),
              // Today Section
              _buildTodaySection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditTaskDialog(),
        backgroundColor: Colors.purple,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- Widgets ---
  Widget _buildSearchBar(double width, double height) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Try to find task....",
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04, vertical: height * 0.012),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Search",
              style:
                  GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.amber : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildTaskSection(String title, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: userTasksRef.where('status', isEqualTo: status).orderBy('date').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Text("No tasks", style: TextStyle(color: Colors.white));
            return Column(
              children: docs.map((doc) {
                final data = doc.data()! as Map<String, dynamic>;
                return _buildTaskCard(data, doc.id);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today task",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: userTasksRef.where('status', isEqualTo: 'future').orderBy('date').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container();
            final docs = snapshot.data!.docs;
            final todayTasks = docs.where((doc) {
              final date = (doc['date'] as Timestamp).toDate();
              return date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
            }).toList();

            if (todayTasks.isEmpty) return const Text("No tasks for today", style: TextStyle(color: Colors.white));
            return Column(
              children: todayTasks.map((doc) {
                final data = doc.data()! as Map<String, dynamic>;
                return _buildTaskCard(data, doc.id);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data, String docId) {
    final dateFormatted = DateFormat('d, MMM, yyyy').format((data['date'] as Timestamp).toDate());
    return GestureDetector(
      onLongPress: () => _showAddOrEditTaskDialog(editData: data, docId: docId),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.circle_outlined, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
                    Text(dateFormatted, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => userTasksRef.doc(docId).delete(),
                ),
                Icon(Icons.flag, color: data['flagColor'] != null ? Color(data['flagColor']) : Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: const Color(0xFF1E1E1E),
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {},
              child: _buildBottomNavItem(Icons.home, "Home", true),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CalendarScreen(tasksPerDay: {})),
                );
              },
              child: _buildBottomNavItem(Icons.calendar_today, "Calendar", false),
            ),
            const SizedBox(width: 48),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const CategoryScreen()));
              },
              child: _buildBottomNavItem(Icons.category, "Category", false),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Graphscreen()));
              },
              child: _buildBottomNavItem(Icons.show_chart, "Graph", false),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showAddOrEditTaskDialog({Map<String, dynamic>? editData, String? docId}) {
    final titleController = TextEditingController(text: editData?['title'] ?? '');
    final descController = TextEditingController(text: editData?['desc'] ?? '');
    DateTime? selectedDate = editData != null ? (editData['date'] as Timestamp).toDate() : DateTime.now();
    TimeOfDay? selectedTime;
    if (editData != null && editData['time'] != null) {
      final parts = (editData['time'] as String).split(":");
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(editData != null ? "Edit Task" : "Add Task"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Task Title")),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Date: "),
                    Text(selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : "Not selected"),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Time: "),
                    Text(selectedTime != null ? selectedTime!.format(context) : "Not selected"),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) setState(() => selectedTime = time);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedDate == null) return;
                final taskData = {
                  'title': titleController.text,
                  'desc': descController.text,
                  'date': Timestamp.fromDate(selectedDate!),
                  'time': selectedTime != null ? selectedTime!.format(context) : null,
                  'status': 'future',
                  'flagColor': Colors.red.value,
                };

                if (editData != null && docId != null) {
                  await userTasksRef.doc(docId).update(taskData);
                } else {
                  await userTasksRef.add(taskData);
                }

                if (selectedDate != null) {
                  DateTime notifyTime = selectedDate!;
                  if (selectedTime != null) {
                    notifyTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute);
                  }
                  scheduleDailyTaskNotification(titleController.text, notifyTime);
                }

                Navigator.pop(context);
              },
              child: Text(editData != null ? "Update" : "Add"),
            ),
          ],
        ),
      ),
    );
  }
}

*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:task_management_todo/Calendar/Calendar_Screen.dart';
import 'package:task_management_todo/BottomNavScreens/Category_screen.dart';
import 'package:task_management_todo/BottomNavScreens/GraphScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? currentUser;
  late CollectionReference userTasksRef;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  TextEditingController searchController = TextEditingController();
  String selectedCategory = "All Task";

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;

    userTasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('tasks');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _checkMissedTasks();
  }

  // --- Notifications ---
  Future<void> scheduleDailyTaskNotification(
      String title, DateTime taskDateTime) async {
    final now = DateTime.now();
    DateTime notifyTime = taskDateTime;

    if (notifyTime.isBefore(now)) {
      notifyTime = notifyTime.add(const Duration(days: 1));
    }

    int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    Future.delayed(notifyTime.difference(now), () async {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'Task Reminder',
        title,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            channelDescription: 'Reminders for your tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );

      scheduleDailyTaskNotification(title, notifyTime.add(const Duration(days: 1)));
    });
  }

  // --- Missed Tasks ---
  Future<void> _checkMissedTasks() async {
    final snapshot =
        await userTasksRef.where('status', isEqualTo: 'future').get();

    for (var doc in snapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final taskDate = (data['date'] as Timestamp).toDate();
      if (taskDate.isBefore(DateTime.now())) {
        await doc.reference.update({'status': 'missed'});

        await flutterLocalNotificationsPlugin.show(
          doc.hashCode,
          'Task Missed!',
          data['title'],
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'missed_channel',
              'Missed Tasks',
              channelDescription: 'Tasks you missed',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final username =
        currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'User';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.12),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          flexibleSpace: Padding(
            padding: EdgeInsets.only(
                top: height * 0.05, left: width * 0.05, right: width * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Hi $username",
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 6),
                      child: Text(
                        "to-do",
                        style: GoogleFonts.poppins(
                            fontSize: width * 0.03,
                            color: Colors.black,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 26),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/onboarding', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              _buildSearchBar(width, height),

              // Filter Chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildChip("All Task"),
                    _buildChip("Work"),
                    _buildChip("Personal"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Future Section
              _buildTaskSection("Future", "future"),

              const SizedBox(height: 20),
              // Today Section
              _buildTodaySection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditTaskDialog(),
        backgroundColor: Colors.purple,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSearchBar(double width, double height) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Try to find task....",
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // trigger search filter
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04, vertical: height * 0.012),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Search",
              style:
                  GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredTasks(String status) {
    Query query = userTasksRef.where('status', isEqualTo: status).orderBy('date');

    if (selectedCategory != "All Task") {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    if (searchController.text.isNotEmpty) {
      // Note: Firestore doesn't support full text search; you can filter client-side later
    }

    return query.snapshots();
  }

  Widget _buildTaskSection(String title, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _getFilteredTasks(status),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final docs = snapshot.data!.docs;
            final filteredDocs = docs.where((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              if (searchController.text.isEmpty) return true;
              return data['title']
                  .toString()
                  .toLowerCase()
                  .contains(searchController.text.toLowerCase());
            }).toList();

            if (filteredDocs.isEmpty)
              return const Text("No tasks", style: TextStyle(color: Colors.white));

            return Column(
              children: filteredDocs.map((doc) {
                final data = doc.data()! as Map<String, dynamic>;
                return _buildTaskCard(data, doc.id);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today task",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _getFilteredTasks("future"),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container();
            final docs = snapshot.data!.docs;
            final todayTasks = docs.where((doc) {
              final date = (doc['date'] as Timestamp).toDate();
              final data = doc.data()! as Map<String, dynamic>;
              if (selectedCategory != "All Task" &&
                  data['category'] != selectedCategory) return false;
              if (searchController.text.isNotEmpty &&
                  !data['title']
                      .toString()
                      .toLowerCase()
                      .contains(searchController.text.toLowerCase())) return false;
              return date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
            }).toList();

            if (todayTasks.isEmpty)
              return const Text("No tasks for today", style: TextStyle(color: Colors.white));

            return Column(
              children: todayTasks.map((doc) {
                final data = doc.data()! as Map<String, dynamic>;
                return _buildTaskCard(data, doc.id);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data, String docId) {
    final dateFormatted = DateFormat('d, MMM, yyyy').format((data['date'] as Timestamp).toDate());
    return GestureDetector(
      onLongPress: () => _showAddOrEditTaskDialog(editData: data, docId: docId),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.circle_outlined, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
                    Text(dateFormatted, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => userTasksRef.doc(docId).delete(),
                ),
                Icon(Icons.flag, color: data['flagColor'] != null ? Color(data['flagColor']) : Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: const Color(0xFF1E1E1E),
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {},
              child: _buildBottomNavItem(Icons.home, "Home", true),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CalendarScreen(tasksPerDay: {})),
                );
              },
              child: _buildBottomNavItem(Icons.calendar_today, "Calendar", false),
            ),
            const SizedBox(width: 48),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const CategoryScreen()));
              },
              child: _buildBottomNavItem(Icons.category, "Category", false),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Graphscreen()));
              },
              child: _buildBottomNavItem(Icons.show_chart, "Graph", false),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showAddOrEditTaskDialog({Map<String, dynamic>? editData, String? docId}) {
    final titleController = TextEditingController(text: editData?['title'] ?? '');
    final descController = TextEditingController(text: editData?['desc'] ?? '');
    final categoryController = TextEditingController(text: editData?['category'] ?? "Personal");
    DateTime? selectedDate = editData != null ? (editData['date'] as Timestamp).toDate() : DateTime.now();
    TimeOfDay? selectedTime;
    if (editData != null && editData['time'] != null) {
      final parts = (editData['time'] as String).split(":");
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(editData != null ? "Edit Task" : "Add Task"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Task Title")),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category (Work/Personal)")),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Date: "),
                    Text(selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : "Not selected"),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Time: "),
                    Text(selectedTime != null ? selectedTime!.format(context) : "Not selected"),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) setState(() => selectedTime = time);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedDate == null) return;
                final taskData = {
                  'title': titleController.text,
                  'desc': descController.text,
                  'category': categoryController.text,
                  'date': Timestamp.fromDate(selectedDate!),
                  'time': selectedTime != null ? selectedTime!.format(context) : null,
                  'status': 'future',
                  'flagColor': Colors.red.value,
                };

                if (editData != null && docId != null) {
                  await userTasksRef.doc(docId).update(taskData);
                } else {
                  await userTasksRef.add(taskData);
                }

                if (selectedDate != null) {
                  DateTime notifyTime = selectedDate!;
                  if (selectedTime != null) {
                    notifyTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute);
                  }
                  scheduleDailyTaskNotification(titleController.text, notifyTime);
                }

                Navigator.pop(context);
              },
              child: Text(editData != null ? "Update" : "Add"),
            ),
          ],
        ),
      ),
    );
  }
}
