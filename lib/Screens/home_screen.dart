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
import 'package:task_management_todo/ProfileView/Profile_Screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? currentUser;
  late CollectionReference userTasksRef;
  late Stream<DocumentSnapshot> userDocStream;
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

    userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .snapshots();

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
    if (taskDateTime.isBefore(now)) return;

    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    Future.delayed(taskDateTime.difference(now), () async {
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

      final date = taskTimestamp.toDate();
      final timeParts = data['time'] != null
          ? (data['time'] as String)
                .split(":")
                .map((e) => int.tryParse(e) ?? 0)
                .toList()
          : [0, 0];
      final taskDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        timeParts[0],
        timeParts[1],
      );

      if (taskDateTime.isBefore(DateTime.now()) && data['status'] == 'future') {
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.12),
        child: AppBar(
          flexibleSpace: Padding(
            padding: EdgeInsets.only(
              top: height * 0.05,
              left: width * 0.05,
              right: width * 0.05,
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: userDocStream,
              builder: (context, snapshot) {
                String username = 'User';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  username =
                      data['name'] ??
                      currentUser?.email?.split('@')[0] ??
                      'User';
                }

                return Row(
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
                      icon: const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Profile()),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
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
                    ...tasksNotifier.value
                        .map((e) => e['category']?.toString())
                        .toSet()
                        .where((c) => c != null && c != 'All')
                        .map(
                          (c) => _buildChip(c!, selectedCategory == c, theme),
                        )
                        .toList(),
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
      onTap: () => setState(() => selectedCategory = label),
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
    final now = DateTime.now();
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
              final ts = doc['date'] as Timestamp?;
              if (ts == null) return false;
              final date = ts.toDate();
              final timeParts = doc['time'] != null
                  ? (doc['time'] as String)
                        .split(":")
                        .map((e) => int.tryParse(e) ?? 0)
                        .toList()
                  : [0, 0];
              final taskDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                timeParts[0],
                timeParts[1],
              );
              return date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day &&
                  taskDateTime.isAfter(now) &&
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
                        decoration: status == 'done'
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
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
                if (status != 'done')
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Mark as Done',
                    onPressed: () async {
                      await userTasksRef.doc(docId).update({'status': 'done'});
                      final updatedTasks = tasksNotifier.value.map((t) {
                        if (t['docId'] == docId) t['status'] = 'done';
                        return t;
                      }).toList();
                      tasksNotifier.value = updatedTasks;
                    },
                  ),
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
                          : "",
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Time: "),
                    Text(
                      selectedTime != null ? selectedTime!.format(context) : "",
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null)
                          setState(() => selectedTime = picked);
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
                if (titleController.text.isEmpty) return;
                final taskData = {
                  'title': titleController.text,
                  'desc': descController.text,
                  'date': selectedDate != null
                      ? Timestamp.fromDate(selectedDate!)
                      : null,
                  'time': selectedTime != null
                      ? "${selectedTime!.hour}:${selectedTime!.minute}"
                      : null,
                  'category': 'General',
                  'status': 'future',
                  'flagColor': Colors.red.value,
                };
                if (docId != null) {
                  await userTasksRef.doc(docId).update(taskData);
                } else {
                  await userTasksRef.add(taskData);
                  if (selectedDate != null && selectedTime != null) {
                    final taskDateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                    await scheduleTaskNotification(
                      titleController.text,
                      taskDateTime,
                    );
                  }
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

/*

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:task_management_todo/Calendar/Calendar_Screen.dart';
import 'package:task_management_todo/BottomNavScreens/SettingScreen.dart';
import 'package:task_management_todo/BottomNavScreens/GraphScreen.dart';
import 'package:task_management_todo/ProfileView/Profile_Screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? currentUser;
  late CollectionReference userTasksRef;
  late Stream<DocumentSnapshot> userDocStream;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  ValueNotifier<List<Map<String, dynamic>>> tasksNotifier = ValueNotifier([]);
  String searchQuery = '';
  String selectedCategory = 'All';

  // subscription for task list snapshots
  StreamSubscription<QuerySnapshot>? _tasksSub;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    userTasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('tasks');

    userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .snapshots();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _startListeningTasks();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    tasksNotifier.dispose();
    super.dispose();
  }

  // Start listening to tasks and normalize status/time, update missed statuses server-side if needed
  void _startListeningTasks() {
    _tasksSub = userTasksRef.snapshots().listen((snapshot) async {
      final now = DateTime.now();
      List<Map<String, dynamic>> taskList = [];

      for (var doc in snapshot.docs) {
        final dataRaw = doc.data()! as Map<String, dynamic>;
        // Defensive copy
        final data = Map<String, dynamic>.from(dataRaw);

        // Normalize status: some older docs used isDone boolean
        if (data.containsKey('isDone') && data['isDone'] == true) {
          data['status'] = 'done';
        } else {
          data['status'] = (data['status'] ?? 'future');
        }

        // Parse timestamp and time robustly
        Timestamp? ts = data['date'] as Timestamp?;
        DateTime? date = ts?.toDate();

        // Parse time string like "14:6" or "2:06"
        int hour = 0;
        int minute = 0;
        if (data['time'] != null && (data['time'] as String).isNotEmpty) {
          try {
            final parts =
                (data['time'] as String).split(':').map((e) => e.trim()).toList();
            if (parts.isNotEmpty) {
              hour = int.tryParse(parts[0]) ?? 0;
            }
            if (parts.length > 1) {
              minute = int.tryParse(parts[1]) ?? 0;
            }
          } catch (_) {
            hour = 0;
            minute = 0;
          }
        }

        DateTime? taskDateTime;
        if (date != null) {
          taskDateTime = DateTime(date.year, date.month, date.day, hour, minute);
        }

        // If the task's datetime is in the past and status is 'future', mark it missed in Firestore.
        // This ensures UI stays consistent dynamically.
        if (taskDateTime != null &&
            taskDateTime.isBefore(now) &&
            data['status'] == 'future') {
          try {
            await doc.reference.update({'status': 'missed'});
            data['status'] = 'missed'; // reflect locally for this snapshot
          } catch (e) {
            // ignore update errors but don't crash UI
          }
        }

        // set docId for later actions
        data['docId'] = doc.id;
        taskList.add(data);
      }

      // assign to notifier (UI will rebuild)
      tasksNotifier.value = taskList;
    });
  }

  Future<void> scheduleTaskNotification(
    String title,
    DateTime taskDateTime,
  ) async {
    final now = DateTime.now();
    if (taskDateTime.isBefore(now)) return;

    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    Future.delayed(taskDateTime.difference(now), () async {
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

  List<Map<String, dynamic>> get filteredTasks {
    return tasksNotifier.value.where((task) {
      final matchesCategory =
          selectedCategory == 'All' || (task['category'] ?? 'General') == selectedCategory;
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.12),
        child: AppBar(
          flexibleSpace: Padding(
            padding: EdgeInsets.only(
              top: height * 0.05,
              left: width * 0.05,
              right: width * 0.05,
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: userDocStream,
              builder: (context, snapshot) {
                String username = 'User';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  username =
                      data['name'] ?? currentUser?.email?.split('@')[0] ?? 'User';
                }

                return Row(
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
                      icon: const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Profile()),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
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
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: tasksNotifier,
                  builder: (context, tasksValue, _) {
                    final categories = <String>{'All'};
                    for (var t in tasksValue) {
                      final c = (t['category'] ?? 'General').toString();
                      if (c.isNotEmpty) categories.add(c);
                    }
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: categories
                          .map((c) => _buildChip(c, selectedCategory == c, Theme.of(context)))
                          .toList(),
                    );
                  },
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
      onTap: () => setState(() => selectedCategory = label),
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
              color: isSelected ? Colors.black : theme.textTheme.bodyMedium?.color,
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
            final filtered = filteredTasks.where((t) => (t['status'] ?? 'future') == status).toList();
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
    final now = DateTime.now();
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
              final ts = doc['date'] as Timestamp?;
              if (ts == null) return false;
              final date = ts.toDate();
              final timeParts = (doc['time'] as String?)?.split(':') ?? ['0','0'];
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
              final taskDateTime = DateTime(date.year, date.month, date.day, hour, minute);
              return date.year == now.year &&
                  date.month == now.month &&
                  date.day == now.day &&
                  taskDateTime.isAfter(now) &&
                  (doc['status'] ?? 'future') == 'future';
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
    if (!redFlag && !greenFlag && data['flagColor'] != null) {
      try {
        flagColor = Color((data['flagColor'] as int));
      } catch (_) {
        flagColor = Colors.red;
      }
    }

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
                        decoration: status == 'done'
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
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
                if (status != 'done')
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Mark as Done',
                    onPressed: () async {
                      try {
                        await userTasksRef.doc(docId).update({
                          'status': 'done',
                          'isDone': true,
                        });
                        // snapshot listener will update tasksNotifier automatically
                      } catch (e) {
                        // optional: show error
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    try {
                      await userTasksRef.doc(docId).delete();
                      // snapshot listener will remove it from notifier
                    } catch (e) {}
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
    if (editData != null && editData['time'] != null && (editData['time'] as String).isNotEmpty) {
      final parts = (editData['time'] as String).split(":");
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      selectedTime = TimeOfDay(hour: h, minute: m);
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                            : "",
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final today = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? today,
                          firstDate: today, // prevent picking past dates
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Time: "),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedTime != null ? selectedTime!.format(context) : "",
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          // If user selected a time that would make the datetime in the past, warn and ignore
                          if (selectedDate != null) {
                            final combined = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              picked.hour,
                              picked.minute,
                            );
                            if (combined.isBefore(DateTime.now())) {
                              // show a small message and don't accept it
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot select a past time.'),
                                  ),
                                );
                              }
                              return;
                            }
                          }
                          setState(() => selectedTime = picked);
                        }
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
                if (titleController.text.isEmpty) return;

                // Save time as padded 24-hour "HH:mm"
                String? timeString;
                if (selectedTime != null) {
                  timeString =
                      "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";
                }

                final taskData = {
                  'title': titleController.text,
                  'desc': descController.text,
                  'date': selectedDate != null ? Timestamp.fromDate(selectedDate!) : null,
                  'time': timeString,
                  'category': editData != null ? (editData['category'] ?? 'General') : 'General',
                  'status': editData != null ? (editData['status'] ?? 'future') : 'future',
                  'flagColor': editData != null ? (editData['flagColor'] ?? Colors.red.value) : Colors.red.value,
                };

                try {
                  if (docId != null) {
                    await userTasksRef.doc(docId).update(taskData);
                    // notification reschedule could be added here for edits
                  } else {
                    final docRef = await userTasksRef.add(taskData);
                    if (selectedDate != null && selectedTime != null) {
                      final taskDateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                      await scheduleTaskNotification(
                        titleController.text,
                        taskDateTime,
                      );
                    }
                  }
                } catch (e) {
                  // handle error (optional)
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

// Your existing imports remain the same
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:task_management_todo/Calendar/Calendar_Screen.dart';
import 'package:task_management_todo/BottomNavScreens/SettingScreen.dart';
import 'package:task_management_todo/BottomNavScreens/GraphScreen.dart';
import 'package:task_management_todo/ProfileView/Profile_Screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? currentUser;
  late CollectionReference userTasksRef;
  late Stream<DocumentSnapshot> userDocStream;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  ValueNotifier<List<Map<String, dynamic>>> tasksNotifier = ValueNotifier([]);
  String searchQuery = '';
  String selectedCategory = 'All';
  StreamSubscription<QuerySnapshot>? _tasksSub;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    userTasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('tasks');

    userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .snapshots();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    _startListeningTasks();
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    tasksNotifier.dispose();
    super.dispose();
  }

  void _startListeningTasks() {
    _tasksSub = userTasksRef.snapshots().listen((snapshot) async {
      final now = DateTime.now();
      final Map<String, Map<String, dynamic>> taskMap = {};

      for (var doc in snapshot.docs) {
        final dataRaw = doc.data()! as Map<String, dynamic>;
        final data = Map<String, dynamic>.from(dataRaw);

        // Normalize isDone to status
        if (data['isDone'] == true) {
          data['status'] = 'done';
        } else {
          data['status'] = (data['status'] ?? 'future');
        }

        // Combine date and time
        Timestamp? ts = data['date'] as Timestamp?;
        DateTime? date = ts?.toDate();
        int hour = 0, minute = 0;
        if (data['time'] != null && (data['time'] as String).isNotEmpty) {
          final parts = (data['time'] as String).split(':');
          hour = int.tryParse(parts[0]) ?? 0;
          minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
        }

        DateTime? taskDateTime;
        if (date != null) {
          taskDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          );
        }

        // Mark missed if past
        if (taskDateTime != null &&
            taskDateTime.isBefore(now) &&
            data['status'] == 'future') {
          try {
            await doc.reference.update({'status': 'missed'});
            data['status'] = 'missed';
          } catch (_) {}
        }

        data['docId'] = doc.id;

        // Store unique task by docId
        taskMap[doc.id] = data;
      }

      tasksNotifier.value = taskMap.values.toList();
    });
  }

  Future<void> scheduleTaskNotification(
    String title,
    DateTime taskDateTime,
  ) async {
    final now = DateTime.now();
    if (taskDateTime.isBefore(now)) return;

    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    Future.delayed(taskDateTime.difference(now), () async {
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

  List<Map<String, dynamic>> get filteredTasks {
    final filtered = tasksNotifier.value.where((task) {
      final matchesCategory =
          selectedCategory == 'All' ||
          (task['category'] ?? 'General') == selectedCategory;
      final matchesSearch =
          searchQuery.isEmpty ||
          (task['title']?.toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false);
      return matchesCategory && matchesSearch;
    }).toList();

    // Remove duplicates just in case
    final seen = <String>{};
    final uniqueList = <Map<String, dynamic>>[];
    for (var t in filtered) {
      if (!seen.contains(t['docId'])) {
        seen.add(t['docId']);
        uniqueList.add(t);
      }
    }

    return uniqueList;
  }

  List<Map<String, dynamic>> getTodayTasks() {
    final now = DateTime.now();
    final todayTasks = filteredTasks.where((doc) {
      final ts = doc['date'] as Timestamp?;
      if (ts == null) return false;
      final date = ts.toDate();

      final timeParts = (doc['time'] as String?)?.split(':') ?? ['0', '0'];
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute =
          int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0;
      final taskDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      // Task is for today and not missed or done
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day &&
          (doc['status'] ?? 'future') == 'future';
    }).toList();

    // Remove duplicates just in case
    final seen = <String>{};
    final uniqueList = <Map<String, dynamic>>[];
    for (var t in todayTasks) {
      if (!seen.contains(t['docId'])) {
        seen.add(t['docId']);
        uniqueList.add(t);
      }
    }

    return uniqueList;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.12),
        child: AppBar(
          flexibleSpace: Padding(
            padding: EdgeInsets.only(
              top: height * 0.05,
              left: width * 0.05,
              right: width * 0.05,
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: userDocStream,
              builder: (context, snapshot) {
                String username = 'User';
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  username =
                      data['name'] ??
                      currentUser?.email?.split('@')[0] ??
                      'User';
                }

                return Row(
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
                      icon: const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Profile()),
                          );
                        }
                      },
                    ),
                  ],
                );
              },
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
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: tasksNotifier,
                  builder: (context, tasksValue, _) {
                    final categories = <String>{'All'};
                    for (var t in tasksValue) {
                      final c = (t['category'] ?? 'General').toString();
                      if (c.isNotEmpty) categories.add(c);
                    }
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: categories
                          .map(
                            (c) => _buildChip(c, selectedCategory == c, theme),
                          )
                          .toList(),
                    );
                  },
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
      onTap: () => setState(() => selectedCategory = label),
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
    if (!redFlag && !greenFlag && data['flagColor'] != null) {
      try {
        flagColor = Color((data['flagColor'] as int));
      } catch (_) {
        flagColor = Colors.red;
      }
    }

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
                        decoration: status == 'done'
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
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
                if (status != 'done')
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Mark as Done',
                    onPressed: () async {
                      try {
                        await userTasksRef.doc(docId).update({
                          'status': 'done',
                          'isDone': true,
                        });
                        // snapshot listener will update tasksNotifier automatically
                      } catch (e) {
                        // optional: show error
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    try {
                      await userTasksRef.doc(docId).delete();
                      // snapshot listener will remove it from notifier
                    } catch (e) {}
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
    if (editData != null &&
        editData['time'] != null &&
        (editData['time'] as String).isNotEmpty) {
      final parts = (editData['time'] as String).split(":");
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      selectedTime = TimeOfDay(hour: h, minute: m);
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                            : "",
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final today = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? today,
                          firstDate: today, // prevent picking past dates
                          lastDate: DateTime(2100),
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Time: "),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedTime != null
                            ? selectedTime!.format(context)
                            : "",
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          // If user selected a time that would make the datetime in the past, warn and ignore
                          if (selectedDate != null) {
                            final combined = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              picked.hour,
                              picked.minute,
                            );
                            if (combined.isBefore(DateTime.now())) {
                              // show a small message and don't accept it
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot select a past time.'),
                                  ),
                                );
                              }
                              return;
                            }
                          }
                          setState(() => selectedTime = picked);
                        }
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
                if (titleController.text.isEmpty) return;

                // Save time as padded 24-hour "HH:mm"
                String? timeString;
                if (selectedTime != null) {
                  timeString =
                      "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";
                }

                final taskData = {
                  'title': titleController.text,
                  'desc': descController.text,
                  'date': selectedDate != null
                      ? Timestamp.fromDate(selectedDate!)
                      : null,
                  'time': timeString,
                  'category': editData != null
                      ? (editData['category'] ?? 'General')
                      : 'General',
                  'status': editData != null
                      ? (editData['status'] ?? 'future')
                      : 'future',
                  'flagColor': editData != null
                      ? (editData['flagColor'] ?? Colors.red.value)
                      : Colors.red.value,
                };

                try {
                  if (docId != null) {
                    await userTasksRef.doc(docId).update(taskData);
                    // notification reschedule could be added here for edits
                  } else {
                    final docRef = await userTasksRef.add(taskData);
                    if (selectedDate != null && selectedTime != null) {
                      final taskDateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                      await scheduleTaskNotification(
                        titleController.text,
                        taskDateTime,
                      );
                    }
                  }
                } catch (e) {
                  // handle error (optional)
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

  Widget _buildTodaySection(ThemeData theme) {
    final todayTasks = getTodayTasks();
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
        if (todayTasks.isEmpty)
          Text(
            "No tasks for today",
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ...todayTasks
            .map((doc) => _buildTaskCard(doc, doc['docId'], theme: theme))
            .toList(),
      ],
    );
  }

  Widget _buildTaskSection(
    String title,
    String status, {
    bool redFlag = false,
    bool greenFlag = false,
    required ThemeData theme,
  }) {
    // Filter tasks by status
    final tasks = filteredTasks
        .where((t) => (t['status'] ?? 'future') == status)
        .toList();

    // Remove duplicates by docId
    final seen = <String>{};
    final uniqueTasks = <Map<String, dynamic>>[];
    for (var t in tasks) {
      if (!seen.contains(t['docId'])) {
        seen.add(t['docId']);
        uniqueTasks.add(t);
      }
    }

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
        if (uniqueTasks.isEmpty)
          Text(
            "No tasks",
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ...uniqueTasks.map(
          (data) => _buildTaskCard(
            data,
            data['docId'],
            redFlag: redFlag,
            greenFlag: greenFlag,
            theme: theme,
          ),
        ),
      ],
    );
  }
}
