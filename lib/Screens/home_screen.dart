/*
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:task_management_todo/Calendar/Calendar_Screen.dart';
import 'package:task_management_todo/BottomNavScreens/SettingScreen.dart';
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
  ValueNotifier<List<Map<String, dynamic>>> tasksNotifier = ValueNotifier([]);
  String searchQuery = '';
  String selectedCategory = 'All';

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

    _fetchTasks();
    _checkMissedTasks();
  }

  // --- Fetch tasks reactively ---
  void _fetchTasks() {
    userTasksRef.snapshots().listen((snapshot) {
      List<Map<String, dynamic>> taskList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        data['docId'] = doc.id;
        taskList.add(data);
      }
      tasksNotifier.value = taskList;
    });
  }

  // --- Notifications (original Future.delayed style) ---
  Future<void> scheduleTaskNotification(
    String title,
    DateTime taskDateTime,
  ) async {
    final now = DateTime.now();
    DateTime notifyTime = taskDateTime;

    if (notifyTime.isBefore(now)) {
      notifyTime = notifyTime.add(const Duration(days: 1));
    }

    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

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
    });
  }

  // --- Missed tasks check ---
  Future<void> _checkMissedTasks() async {
    final snapshot = await userTasksRef.get();
    for (var doc in snapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final taskTimestamp = data['date'] as Timestamp?;
      if (taskTimestamp == null) continue; // skip tasks without date
      final taskDate = taskTimestamp.toDate();

      if (taskDate.isBefore(DateTime.now()) && data['status'] == 'future') {
        await doc.reference.update({'status': 'missed'});
      }
    }
  }

  // --- Filtered tasks based on search & category ---
  List<Map<String, dynamic>> get filteredTasks {
    return tasksNotifier.value.where((task) {
      final matchesCategory =
          selectedCategory == 'All' || task['category'] == selectedCategory;
      final matchesSearch =
          searchQuery.isEmpty ||
          (task['title']?.toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false);
      return matchesCategory && matchesSearch;
    }).toList();
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
              top: height * 0.05,
              left: width * 0.05,
              right: width * 0.05,
            ),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 6,
                      ),
                      child: Text(
                        "to-do",
                        style: GoogleFonts.poppins(
                          fontSize: width * 0.03,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
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
                        context,
                        '/onboarding',
                        (route) => false,
                      );
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
              _buildSearchBar(width, height),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildChip("All", selectedCategory == 'All'),
                    _buildChip("Work", selectedCategory == 'Work'),
                    _buildChip("Personal", selectedCategory == 'Personal'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildTaskSection("Future Tasks", "future"),
              const SizedBox(height: 20),
              _buildTodaySection(),
              const SizedBox(height: 20),
              _buildTaskSection("Missed Tasks", "missed", redFlag: true),
              const SizedBox(height: 20),
              _buildTaskSection("Completed Tasks", "done", greenFlag: true),
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

  // ---------------- Widgets ----------------
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
              onChanged: (value) => setState(() => searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Try to find task....",
                hintStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() {
        selectedCategory = label;
      }),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskSection(
    String title,
    String status, {
    bool redFlag = false,
    bool greenFlag = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: tasksNotifier,
          builder: (context, tasks, _) {
            final filtered = filteredTasks
                .where((t) => t['status'] == status)
                .toList();
            if (filtered.isEmpty)
              return const Text(
                "No tasks",
                style: TextStyle(color: Colors.white),
              );
            return Column(
              children: filtered
                  .map(
                    (data) => _buildTaskCard(
                      data,
                      data['docId'],
                      redFlag: redFlag,
                      greenFlag: greenFlag,
                    ),
                  )
                  .toList(),
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
        Text(
          "Today's Tasks",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: tasksNotifier,
          builder: (context, tasks, _) {
            final todayTasks = filteredTasks.where((doc) {
              final dateTimestamp = doc['date'] as Timestamp?;
              if (dateTimestamp == null) return false;
              final date = dateTimestamp.toDate();

              return date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day &&
                  doc['status'] == 'future';
            }).toList();

            if (todayTasks.isEmpty)
              return const Text(
                "No tasks for today",
                style: TextStyle(color: Colors.white),
              );

            return Column(
              children: todayTasks
                  .map((doc) => _buildTaskCard(doc, doc['docId']))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    Map<String, dynamic> data,
    String docId, {
    bool redFlag = false,
    bool greenFlag = false,
  }) {
    final Timestamp? timestamp = data['date'] as Timestamp?;
    final dateFormatted = timestamp != null
        ? DateFormat('d, MMM, yyyy').format(timestamp.toDate())
        : "No date";

    final status = data['status'] ?? 'future';
    Color flagColor = Colors.red;
    if (greenFlag) flagColor = Colors.green;
    if (!redFlag && !greenFlag && data['flagColor'] != null)
      flagColor = Color(data['flagColor']);

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
                Icon(
                  Icons.circle_outlined,
                  color: Colors.white.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? "No title",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      dateFormatted,
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await userTasksRef.doc(docId).delete();
                    tasksNotifier.value = tasksNotifier.value
                        .where((t) => t['docId'] != docId)
                        .toList();
                  },
                ),
                Icon(Icons.flag, color: flagColor),
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
                    builder: (context) => CalendarScreen(
                      tasksPerDay: {},
                      userTasksRef: userTasksRef,
                    ),
                  ),
                );
              },
              child: _buildBottomNavItem(
                Icons.calendar_today,
                "Calendar",
                false,
              ),
            ),
            const SizedBox(width: 48),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Graphscreen(),
                  ),
                );
              },
              child: _buildBottomNavItem(Icons.show_chart_sharp, "Charts", false),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              child: _buildBottomNavItem(Icons.settings, "Setting", false),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showAddOrEditTaskDialog({
    Map<String, dynamic>? editData,
    String? docId,
  }) {
    final titleController = TextEditingController(
      text: editData?['title'] ?? '',
    );
    final descController = TextEditingController(text: editData?['desc'] ?? '');
    DateTime? selectedDate = editData != null && editData['date'] != null
        ? (editData['date'] as Timestamp).toDate()
        : DateTime.now();
    TimeOfDay? selectedTime;
    if (editData != null && editData['time'] != null) {
      final parts = (editData['time'] as String).split(":");
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(editData != null ? "Edit Task" : "Add Task"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Task Title"),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Date: "),
                    Text(
                      selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                          : "Not selected",
                    ),
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
                    Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : "Not selected",
                    ),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedDate == null)
                  return;

                final taskData = {
                  'title': titleController.text,
                  'desc': descController.text,
                  'date': Timestamp.fromDate(selectedDate!),
                  'time': selectedTime != null
                      ? "${selectedTime!.hour}:${selectedTime!.minute}"
                      : null,
                  'status': 'future',
                  'flagColor': Colors.red.value,
                  'category': 'Work',
                  'createdAt': Timestamp.now(),
                };

                if (docId != null) {
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
                      selectedTime!.minute,
                    );
                  }
                  scheduleTaskNotification(titleController.text, notifyTime);
                }

                Navigator.pop(context);
              },
              child: const Text("Save"),
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
import 'package:task_management_todo/BottomNavScreens/SettingScreen.dart';
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
  ValueNotifier<List<Map<String, dynamic>>> tasksNotifier = ValueNotifier([]);
  String searchQuery = '';
  String selectedCategory = 'All';

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

    _fetchTasks();
    _checkMissedTasks();
  }

  void _fetchTasks() {
    userTasksRef.snapshots().listen((snapshot) {
      List<Map<String, dynamic>> taskList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        data['docId'] = doc.id;
        taskList.add(data);
      }
      tasksNotifier.value = taskList;
    });
  }

  Future<void> scheduleTaskNotification(
    String title,
    DateTime taskDateTime,
  ) async {
    final now = DateTime.now();
    DateTime notifyTime = taskDateTime;

    if (notifyTime.isBefore(now)) {
      notifyTime = notifyTime.add(const Duration(days: 1));
    }

    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    Future.delayed(notifyTime.difference(now), () async {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        'Task Reminder',
        title,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            channelDescription: 'Reminders for your tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  Future<void> _checkMissedTasks() async {
    final snapshot = await userTasksRef.get();
    for (var doc in snapshot.docs) {
      final data = doc.data()! as Map<String, dynamic>;
      final taskTimestamp = data['date'] as Timestamp?;
      if (taskTimestamp == null) continue;
      final taskDate = taskTimestamp.toDate();

      if (taskDate.isBefore(DateTime.now()) && data['status'] == 'future') {
        await doc.reference.update({'status': 'missed'});
      }
    }
  }

  List<Map<String, dynamic>> get filteredTasks {
    return tasksNotifier.value.where((task) {
      final matchesCategory =
          selectedCategory == 'All' || task['category'] == selectedCategory;
      final matchesSearch =
          searchQuery.isEmpty ||
          (task['title']?.toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final username =
        currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'User';

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.12),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          flexibleSpace: Padding(
            padding: EdgeInsets.only(
              top: height * 0.05,
              left: width * 0.05,
              right: width * 0.05,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "Hi $username",
                      style: GoogleFonts.poppins(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 6,
                      ),
                      child: Text(
                        "to-do",
                        style: GoogleFonts.poppins(
                          fontSize: width * 0.03,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: theme.iconTheme.color,
                    size: 26,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/onboarding',
                        (route) => false,
                      );
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
              _buildSearchBar(width),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildChip("All", selectedCategory == 'All', theme),
                    _buildChip("Work", selectedCategory == 'Work', theme),
                    _buildChip(
                      "Personal",
                      selectedCategory == 'Personal',
                      theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildTaskSection("Future Tasks", "future", theme: theme),
              const SizedBox(height: 20),
              _buildTodaySection(theme),
              const SizedBox(height: 20),
              _buildTaskSection(
                "Missed Tasks",
                "missed",
                redFlag: true,
                theme: theme,
              ),
              const SizedBox(height: 20),
              _buildTaskSection(
                "Completed Tasks",
                "done",
                greenFlag: true,
                theme: theme,
              ),
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
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  Widget _buildSearchBar(double width) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor ?? const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: theme.iconTheme.color?.withOpacity(0.6)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Try to find task....",
                hintStyle: TextStyle(color: theme.hintColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() {
        selectedCategory = label;
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskSection(
    String title,
    String status, {
    bool redFlag = false,
    bool greenFlag = false,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: tasksNotifier,
          builder: (context, tasks, _) {
            final filtered = filteredTasks
                .where((t) => t['status'] == status)
                .toList();
            if (filtered.isEmpty)
              return Text(
                "No tasks",
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              );
            return Column(
              children: filtered
                  .map(
                    (data) => _buildTaskCard(
                      data,
                      data['docId'],
                      redFlag: redFlag,
                      greenFlag: greenFlag,
                      theme: theme,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTodaySection(ThemeData theme) {
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Tasks",
          style: GoogleFonts.poppins(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: tasksNotifier,
          builder: (context, tasks, _) {
            final todayTasks = filteredTasks.where((doc) {
              final dateTimestamp = doc['date'] as Timestamp?;
              if (dateTimestamp == null) return false;
              final date = dateTimestamp.toDate();

              return date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day &&
                  doc['status'] == 'future';
            }).toList();

            if (todayTasks.isEmpty)
              return Text(
                "No tasks for today",
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              );

            return Column(
              children: todayTasks
                  .map((doc) => _buildTaskCard(doc, doc['docId'], theme: theme))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    Map<String, dynamic> data,
    String docId, {
    bool redFlag = false,
    bool greenFlag = false,
    required ThemeData theme,
  }) {
    final Timestamp? timestamp = data['date'] as Timestamp?;
    final dateFormatted = timestamp != null
        ? DateFormat('d, MMM, yyyy').format(timestamp.toDate())
        : "No date";

    final status = data['status'] ?? 'future';
    Color flagColor = Colors.red;
    if (greenFlag) flagColor = Colors.green;
    if (!redFlag && !greenFlag && data['flagColor'] != null)
      flagColor = Color(data['flagColor']);

    return GestureDetector(
      onLongPress: () => _showAddOrEditTaskDialog(editData: data, docId: docId),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.cardColor ?? const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.circle_outlined,
                  color: theme.iconTheme.color?.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? "No title",
                      style: GoogleFonts.poppins(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      dateFormatted,
                      style: GoogleFonts.poppins(
                        color: theme.hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await userTasksRef.doc(docId).delete();
                    tasksNotifier.value = tasksNotifier.value
                        .where((t) => t['docId'] != docId)
                        .toList();
                  },
                ),
                Icon(Icons.flag, color: flagColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return BottomAppBar(
      color: theme.bottomAppBarTheme.color ?? theme.bottomAppBarTheme.color,
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () {},
              child: _buildBottomNavItem(Icons.home, "Home", true, theme),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CalendarScreen(
                      tasksPerDay: {},
                      userTasksRef: userTasksRef,
                    ),
                  ),
                );
              },
              child: _buildBottomNavItem(
                Icons.calendar_today,
                "Calendar",
                false,
                theme,
              ),
            ),
            const SizedBox(width: 48),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Graphscreen()),
                );
              },
              child: _buildBottomNavItem(
                Icons.show_chart_sharp,
                "Charts",
                false,
                theme,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              child: _buildBottomNavItem(
                Icons.settings,
                "Setting",
                false,
                theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isSelected,
    ThemeData theme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? theme.iconTheme.color : Colors.grey,
          size: 24,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.textTheme.bodyMedium?.color : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showAddOrEditTaskDialog({
    Map<String, dynamic>? editData,
    String? docId,
  }) {
    final titleController = TextEditingController(
      text: editData?['title'] ?? '',
    );
    final descController = TextEditingController(text: editData?['desc'] ?? '');
    DateTime? selectedDate = editData != null && editData['date'] != null
        ? (editData['date'] as Timestamp).toDate()
        : DateTime.now();
    TimeOfDay? selectedTime;
    if (editData != null && editData['time'] != null) {
      final parts = (editData['time'] as String).split(":");
      selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(editData != null ? "Edit Task" : "Add Task"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Task Title"),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Date: "),
                    Text(
                      selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                          : "Not selected",
                    ),
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
                    Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : "Not selected",
                    ),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedDate == null)
                  return;

                final taskData = {
                  'title': titleController.text,
                  'desc': descController.text,
                  'date': Timestamp.fromDate(selectedDate!),
                  'time': selectedTime != null
                      ? "${selectedTime!.hour}:${selectedTime!.minute}"
                      : null,
                  'status': 'future',
                  'flagColor': Colors.red.value,
                  'category': 'Work',
                  'createdAt': Timestamp.now(),
                };

                if (docId != null) {
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
                      selectedTime!.minute,
                    );
                  }
                  scheduleTaskNotification(titleController.text, notifyTime);
                }

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
