
/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management_app/BottomNavScreens/GraphScreen.dart';
import 'package:task_management_app/Screens/home_screen.dart';
import 'category_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  int _currentIndex = 1;

  // Store tasks per date
  final Map<String, List<Map<String, dynamic>>> _tasksPerDay = {};

  // Generate days of month
  List<DateTime> _generateMonthDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return List.generate(
        lastDay.day, (index) => DateTime(month.year, month.month, index + 1));
  }

  List<Map<String, dynamic>> get _tasksForSelectedDate {
    final key = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return _tasksPerDay[key] ?? [];
  }

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
      switch (index) {
        case 0:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Home()));
          break;
        case 1:
          break;
        case 2:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const CategoryScreen()));
          break;
        case 3:
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Graphscreen()));
          break;
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + delta, 1);
      _selectedDate = DateTime(_focusedDate.year, _focusedDate.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateMonthDays(_focusedDate);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEEE').format(_selectedDate),
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            Text(DateFormat('d, MMMM, yyyy').format(_selectedDate),
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
            onPressed: () => _changeMonth(-1),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
      body: Column(
        children: [
          // Weekdays
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text("M", style: TextStyle(color: Colors.white)),
                Text("T", style: TextStyle(color: Colors.white)),
                Text("W", style: TextStyle(color: Colors.white)),
                Text("T", style: TextStyle(color: Colors.white)),
                Text("F", style: TextStyle(color: Colors.white)),
                Text("S", style: TextStyle(color: Colors.white)),
                Text("S", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),

          // Scrollable calendar grid
          Flexible(
            flex: 2,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const BouncingScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemBuilder: (context, index) {
                final date = days[index];
                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.amber : Colors.transparent,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Text(
                        "${date.day}",
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Tasks list
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Your Tasks",
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _tasksForSelectedDate.isNotEmpty
                        ? ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _tasksForSelectedDate.length,
                            itemBuilder: (context, index) {
                              final task = _tasksForSelectedDate[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.radio_button_unchecked,
                                            color: Colors.white70, size: 20),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(task["title"],
                                                style: const TextStyle(
                                                    color: Colors.white, fontSize: 16)),
                                            Text(task["time"] ?? "",
                                                style: const TextStyle(
                                                    color: Colors.white54, fontSize: 14)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Icon(Icons.flag, color: task["flagColor"], size: 20),
                                  ],
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Text("No tasks for this day",
                                style: TextStyle(color: Colors.white54)),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E1E),
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "Home", 0),
              _buildNavItem(Icons.calendar_today, "Calendar", 1),
              const SizedBox(width: 40),
              _buildNavItem(Icons.category, "Category", 2),
              _buildNavItem(Icons.bar_chart, "Graph", 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white54, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    Color selectedFlag = Colors.red;
    TimeOfDay? selectedTime;
    DateTime? selectedDate = _selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Add Task", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Task Title",
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder:
                          UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder:
                          UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber))),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text("Flag: ", style: TextStyle(color: Colors.white)),
                    DropdownButton<Color>(
                      dropdownColor: Colors.black,
                      value: selectedFlag,
                      items: const [
                        DropdownMenuItem(
                            value: Colors.red,
                            child: Text("Red", style: TextStyle(color: Colors.red))),
                        DropdownMenuItem(
                            value: Colors.yellow,
                            child: Text("Yellow", style: TextStyle(color: Colors.yellow))),
                        DropdownMenuItem(
                            value: Colors.green,
                            child: Text("Green", style: TextStyle(color: Colors.green))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedFlag = val);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Date: ", style: TextStyle(color: Colors.white)),
                    Text(
                        selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                            : "Not selected",
                        style: const TextStyle(color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text("Time: ", style: TextStyle(color: Colors.white)),
                    Text(selectedTime != null ? selectedTime!.format(context) : "Not selected",
                        style: const TextStyle(color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.access_time, color: Colors.white),
                      onPressed: () async {
                        final now = TimeOfDay.now();
                        final time = await showTimePicker(
                          context: context,
                          initialTime: now,
                        );
                        if (time != null) {
                          if (selectedDate != null &&
                              DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day)
                                  .isAtSameMomentAs(DateTime.now())) {
                            if (time.hour < now.hour ||
                                (time.hour == now.hour && time.minute <= now.minute)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Select a future time!")));
                              return;
                            }
                          }
                          setState(() => selectedTime = time);
                        }
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.white))),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty || selectedDate == null) return;

                final key = DateFormat('yyyy-MM-dd').format(selectedDate!);
                final task = {
                  "title": titleController.text,
                  "flagColor": selectedFlag,
                  "time": selectedTime?.format(context)
                };
                if (_tasksPerDay.containsKey(key)) {
                  _tasksPerDay[key]!.add(task);
                } else {
                  _tasksPerDay[key] = [task];
                }
                setState(() => _selectedDate = selectedDate!);
                Navigator.pop(context);
              },
              child: const Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }
}

*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> tasksPerDay;

  const CalendarScreen({super.key, required this.tasksPerDay});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  List<DateTime> _generateMonthDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return List.generate(lastDay.day, (index) => DateTime(month.year, month.month, index + 1));
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _generateMonthDays(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          DateFormat('EEEE, d MMMM, yyyy').format(_selectedDate),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
            onPressed: () => setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
            }),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
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
              children: const [
                Text("M", style: TextStyle(color: Colors.white)),
                Text("T", style: TextStyle(color: Colors.white)),
                Text("W", style: TextStyle(color: Colors.white)),
                Text("T", style: TextStyle(color: Colors.white)),
                Text("F", style: TextStyle(color: Colors.white)),
                Text("S", style: TextStyle(color: Colors.white)),
                Text("S", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          // Calendar grid
          Expanded(
            flex: 2,
            child: GridView.builder(
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
                final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.amber : Colors.transparent,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Text(
                        "${date.day}",
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Task list
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Your Tasks",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: widget.tasksPerDay[DateFormat('yyyy-MM-dd').format(_selectedDate)]?.length ?? 0,
                      itemBuilder: (context, index) {
                        final task =
                            widget.tasksPerDay[DateFormat('yyyy-MM-dd').format(_selectedDate)]![index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.radio_button_unchecked, color: Colors.white70, size: 20),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(task["title"],
                                          style: const TextStyle(color: Colors.white, fontSize: 16)),
                                      if (task["time"] != null)
                                        Text(task["time"], style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(Icons.flag, color: task["flagColor"], size: 20),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate = _selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add Task"),
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
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
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
                          initialTime: TimeOfDay.now(),
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
              onPressed: () {
                if (selectedDate != null) {
                  final key = DateFormat('yyyy-MM-dd').format(selectedDate!);
                  final task = {
                    "title": titleController.text,
                    "desc": descController.text,
                    "time": selectedTime != null ? selectedTime!.format(context) : null,
                    "flagColor": Colors.red,
                  };
                  setState(() {
                    widget.tasksPerDay[key] = widget.tasksPerDay[key] != null
                        ? [...widget.tasksPerDay[key]!, task]
                        : [task];
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }
}
