
/*

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../Calendar/Components/task_service.dart';
import '../Calendar/Components/task_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required Map tasksPerDay, required CollectionReference<Object?> userTasksRef});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  late TaskService _taskService;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _taskService = TaskService(uid: uid);

    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    _notificationsPlugin.initialize(initSettings);
  }

  List<DateTime> _generateMonthDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return List.generate(lastDay.day, (index) => DateTime(month.year, month.month, index + 1));
  }

  Color getStatusColor(TaskModel task) {
    final theme = Theme.of(context);
    if (task.isDone) return Colors.greenAccent;
    final taskDate = task.date.toDate();
    if (taskDate.isBefore(DateTime.now())) return Colors.redAccent;
    return Colors.amberAccent;
  }

  Future<void> _scheduleNotification(TaskModel task) async {
    final now = DateTime.now();
    DateTime notifyTime = task.date.toDate();

    if (task.time != null) {
      final timeParts = task.time!.split(':');
      notifyTime = DateTime(
        notifyTime.year,
        notifyTime.month,
        notifyTime.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    if (notifyTime.isBefore(now)) return;

    final id = task.id.hashCode;

    await _notificationsPlugin.show(
      id,
      'Task Reminder',
      task.title,
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor ?? (theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey.shade200);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final textColorSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;
    final borderColor = theme.dividerColor;
    final selectedBgColor = theme.colorScheme.secondary;

    final daysInMonth = _generateMonthDays(_selectedDate);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          DateFormat('EEEE, d MMMM, yyyy').format(_selectedDate),
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColorSecondary),
            onPressed: () => setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
            }),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: textColorSecondary),
            onPressed: () => setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Weekday labels
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Text(weekdays[index], style: TextStyle(color: textColor));
              }),
            ),
          ),

          // Calendar grid
          Expanded(
            flex: 2,
            child: StreamBuilder<List<TaskModel>>(
              stream: _taskService.getTasksStream(),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                final taskDates = tasks.map((t) => DateFormat('yyyy-MM-dd').format(t.date.toDate())).toSet();

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const BouncingScrollPhysics(),
                  itemCount: daysInMonth.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final date = daysInMonth[index];
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    final hasTask = taskDates.contains(dateKey);
                    final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? selectedBgColor : Colors.transparent,
                              border: Border.all(color: borderColor),
                            ),
                            child: Center(
                              child: Text(
                                "${date.day}",
                                style: TextStyle(
                                  color: isSelected ? Colors.black : textColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          if (hasTask && !isSelected)
                            Positioned(
                              bottom: 6,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Task list
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Tasks",
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<List<TaskModel>>(
                      stream: _taskService.getTasksStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final key = DateFormat('yyyy-MM-dd').format(_selectedDate);
                        final tasksForDay = snapshot.data!
                            .where((task) => DateFormat('yyyy-MM-dd').format(task.date.toDate()) == key)
                            .toList();

                        if (tasksForDay.isEmpty) {
                          return Center(
                              child: Text("No tasks for this day", style: TextStyle(color: textColorSecondary)));
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: tasksForDay.length,
                          itemBuilder: (context, index) {
                            final task = tasksForDay[index];
                            return GestureDetector(
                              onLongPress: () => _showTaskOptions(task),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.radio_button_unchecked,
                                            color: getStatusColor(task), size: 20),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(task.title, style: TextStyle(color: textColor, fontSize: 16)),
                                            if (task.time != null)
                                              Text(task.time!, style: TextStyle(color: textColorSecondary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Icon(Icons.flag, color: Color(task.flagColor), size: 20),
                                  ],
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
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskOptions(TaskModel task) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      backgroundColor: theme.dialogBackgroundColor,
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.check, color: theme.iconTheme.color),
            title: Text(task.isDone ? "Mark Undone" : "Mark Done", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            onTap: () {
              _taskService.toggleTaskDone(task);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: theme.iconTheme.color),
            title: Text("Edit Task", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            onTap: () {
              Navigator.pop(context);
              _showAddTaskDialog(task: task);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: theme.iconTheme.color),
            title: Text("Delete Task", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            onTap: () {
              _taskService.deleteTask(task.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog({TaskModel? task}) {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    DateTime selectedDate = task?.date.toDate() ?? _selectedDate;
    TimeOfDay? selectedTime;
    if (task?.time != null) {
      final parts = task!.time!.split(':');
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    String category = task?.category ?? 'Other';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text(task == null ? "Add Task" : "Edit Task", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Task Title",
                    labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text("Date: ", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    Text(DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    IconButton(
                      icon: Icon(Icons.calendar_today, color: theme.iconTheme.color),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: theme.brightness == Brightness.dark
                                    ? const ColorScheme.dark()
                                    : const ColorScheme.light(),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text("Time: ", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    Text(selectedTime != null ? selectedTime!.format(context) : "Not selected",
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    IconButton(
                      icon: Icon(Icons.access_time, color: theme.iconTheme.color),
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
              child: Text("Cancel", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;

                final timeString = selectedTime != null ? '${selectedTime!.hour}:${selectedTime!.minute}' : null;

                final newTask = TaskModel(
                  id: task?.id ?? '',
                  title: titleController.text,
                  description: descController.text,
                  date: Timestamp.fromDate(selectedDate),
                  time: timeString,
                  isDone: task?.isDone ?? false,
                  category: category,
                  flagColor: 0xFFFF0000,
                );

                if (task == null) {
                  await _taskService.addTask(newTask);
                } else {
                  await _taskService.updateTask(newTask..id = task.id);
                }

                await _scheduleNotification(newTask);
                Navigator.pop(context);
              },
              child: Text(task == null ? "Add Task" : "Update Task"),
            ),
          ],
        ),
      ),
    );
  }
}



*/


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Calendar/Components/task_service.dart';
import '../Calendar/Components/task_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required Map tasksPerDay, required CollectionReference<Object?> userTasksRef});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  late TaskService _taskService;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _taskService = TaskService(uid: uid);

    _notificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    _notificationsPlugin.initialize(initSettings);
  }

  List<DateTime> _generateMonthDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return List.generate(lastDay.day, (index) => DateTime(month.year, month.month, index + 1));
  }

  Color getStatusColor(TaskModel task) {
    final theme = Theme.of(context);
    if (task.isDone) return Colors.greenAccent.shade400;
    final taskDate = task.date.toDate();
    if (taskDate.isBefore(DateTime.now())) return Colors.redAccent.shade400;
    return Colors.amberAccent.shade400;
  }

  Future<void> _scheduleNotification(TaskModel task) async {
    final now = DateTime.now();
    DateTime notifyTime = task.date.toDate();

    if (task.time != null) {
      final timeParts = task.time!.split(':');
      notifyTime = DateTime(
        notifyTime.year,
        notifyTime.month,
        notifyTime.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    if (notifyTime.isBefore(now)) return;

    final id = task.id.hashCode;

    await _notificationsPlugin.show(
      id,
      'Task Reminder',
      task.title,
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor ?? (theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final textColorSecondary = theme.textTheme.bodyMedium?.color ?? Colors.black54;
    final borderColor = theme.dividerColor;
    final selectedBgColor = theme.colorScheme.secondary;

    final daysInMonth = _generateMonthDays(_selectedDate);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          DateFormat('EEEE, d MMMM, yyyy').format(_selectedDate),
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColorSecondary),
            onPressed: () => setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
            }),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, color: textColorSecondary),
            onPressed: () => setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Weekday labels
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Text(
                  weekdays[index],
                  style: GoogleFonts.poppins(
                    color: textColorSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
            ),
          ),

          // Calendar grid
          Expanded(
            flex: 2,
            child: StreamBuilder<List<TaskModel>>(
              stream: _taskService.getTasksStream(),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                final taskDates = tasks.map((t) => DateFormat('yyyy-MM-dd').format(t.date.toDate())).toSet();

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: daysInMonth.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final date = daysInMonth[index];
                    final dateKey = DateFormat('yyyy-MM-dd').format(date);
                    final hasTask = taskDates.contains(dateKey);
                    final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? selectedBgColor : Colors.transparent,
                          border: Border.all(color: isSelected ? selectedBgColor : borderColor),
                          boxShadow: isSelected
                              ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Center(
                              child: Text(
                                "${date.day}",
                                style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.black : textColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (hasTask && !isSelected)
                              Positioned(
                                bottom: 6,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Task list
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tasks",
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: StreamBuilder<List<TaskModel>>(
                      stream: _taskService.getTasksStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final key = DateFormat('yyyy-MM-dd').format(_selectedDate);
                        final tasksForDay = snapshot.data!
                            .where((task) => DateFormat('yyyy-MM-dd').format(task.date.toDate()) == key)
                            .toList();

                        if (tasksForDay.isEmpty) {
                          return Center(
                              child: Text(
                            "No tasks for this day",
                            style: GoogleFonts.poppins(color: textColorSecondary, fontSize: 16),
                          ));
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: tasksForDay.length,
                          itemBuilder: (context, index) {
                            final task = tasksForDay[index];
                            return GestureDetector(
                              onLongPress: () => _showTaskOptions(task),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.black45
                                          : Colors.grey.shade300,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.circle, color: getStatusColor(task), size: 18),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(task.title,
                                                style: GoogleFonts.poppins(
                                                    color: textColor,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16)),
                                            if (task.time != null)
                                              Text(task.time!,
                                                  style: GoogleFonts.poppins(
                                                      color: textColorSecondary, fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Icon(Icons.flag, color: Color(task.flagColor), size: 20),
                                  ],
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
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskOptions(TaskModel task) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      backgroundColor: theme.dialogBackgroundColor,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.check, color: theme.iconTheme.color),
            title: Text(task.isDone ? "Mark Undone" : "Mark Done",
                style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            onTap: () {
              _taskService.toggleTaskDone(task);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: theme.iconTheme.color),
            title: Text("Edit Task", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            onTap: () {
              Navigator.pop(context);
              _showAddTaskDialog(task: task);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: theme.iconTheme.color),
            title: Text("Delete Task", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            onTap: () {
              _taskService.deleteTask(task.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog({TaskModel? task}) {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: task?.title ?? '');
    final descController = TextEditingController(text: task?.description ?? '');
    DateTime selectedDate = task?.date.toDate() ?? _selectedDate;
    TimeOfDay? selectedTime;
    if (task?.time != null) {
      final parts = task!.time!.split(':');
      selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    String category = task?.category ?? 'Other';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(task == null ? "Add Task" : "Edit Task",
              style: GoogleFonts.poppins(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Task Title",
                    labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  ),
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text("Date: ", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    Text(DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    IconButton(
                      icon: Icon(Icons.calendar_today, color: theme.iconTheme.color),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: theme.brightness == Brightness.dark
                                    ? const ColorScheme.dark()
                                    : const ColorScheme.light(),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text("Time: ", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    Text(selectedTime != null ? selectedTime!.format(context) : "Not selected",
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                    IconButton(
                      icon: Icon(Icons.access_time, color: theme.iconTheme.color),
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
              child: Text("Cancel", style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (titleController.text.isEmpty) return;

                final timeString = selectedTime != null ? '${selectedTime!.hour}:${selectedTime!.minute}' : null;

                final newTask = TaskModel(
                  id: task?.id ?? '',
                  title: titleController.text,
                  description: descController.text,
                  date: Timestamp.fromDate(selectedDate),
                  time: timeString,
                  isDone: task?.isDone ?? false,
                  category: category,
                  flagColor: 0xFFFF0000,
                );

                if (task == null) {
                  await _taskService.addTask(newTask);
                } else {
                  await _taskService.updateTask(newTask..id = task.id);
                }

                await _scheduleNotification(newTask);
                Navigator.pop(context);
              },
              child: Text(task == null ? "Add Task" : "Update Task"),
            ),
          ],
        ),
      ),
    );
  }
}



