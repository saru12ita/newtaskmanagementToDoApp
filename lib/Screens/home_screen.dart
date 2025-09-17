/*
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:task_management_app/BottomNavScreens/Calendar_Screen.dart';
import 'package:task_management_app/BottomNavScreens/Category_screen.dart';
import 'package:task_management_app/BottomNavScreens/GraphScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

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
                      "Vasudev Krishna",
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
                          vertical: 2, horizontal: 6),
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
                const Icon(Icons.settings, color: Colors.white, size: 26),
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
              // Search bar
              Container(
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
                          horizontal: width * 0.04,
                          vertical: height * 0.012,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Search",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Filter chips
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
              Text("Future",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: width * 0.045,
                  )),
              const SizedBox(height: 10),
              _buildTaskCard("Doing housework", "7, june,2023"),
              const SizedBox(height: 10),
              _buildTaskCard("Make a studying plan", "7, june,2023"),
              const SizedBox(height: 20),
              // Today Task
              Text("Today task",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: width * 0.045,
                  )),
              const SizedBox(height: 10),
              _buildTaskCard("Do groceries", "6, june,2023"),
              const SizedBox(height: 10),
              _buildTaskCard("Decorate room", "6, june,2023"),
              const SizedBox(height: 10),
              _buildTaskCard("Prepare music", "6, june,2023"),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.purple,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
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
              // Home
              GestureDetector(
                onTap: () {
                  // Already on Home, maybe pop to root or do nothing
                },
                child: _buildBottomNavItem(Icons.home, "Home", true),
              ),
              // Calendar
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CalendarScreen()),
                  );
                },
                child: _buildBottomNavItem(Icons.calendar_today, "Calendar", false),
              ),
              const SizedBox(width: 48), // space for FAB
              // Category
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CategoryScreen()),
                  );
                },
                child: _buildBottomNavItem(Icons.category, "Category", false),
              ),
              // Graph
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Graphscreen()),
                  );
                },
                child: _buildBottomNavItem(Icons.show_chart, "Graph", false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static Widget _buildTaskCard(String title, String date) {
    return Container(
      padding: const EdgeInsets.all(12),
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
                  Text(title,
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 15)),
                  Text(date,
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const Icon(Icons.flag, color: Colors.red),
        ],
      ),
    );
  }

  static Widget _buildBottomNavItem(
      IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon,
            color: isSelected ? Colors.white : Colors.grey, size: 24),
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
}

*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:task_management_todo/BottomNavScreens/Calendar_Screen.dart';
import 'package:task_management_todo/BottomNavScreens/Category_screen.dart';
import 'package:task_management_todo/BottomNavScreens/GraphScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Map<String, dynamic>>> tasksPerDay = {};

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.12),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          elevation: 0,
          flexibleSpace: Padding(
            padding: EdgeInsets.only(top: height * 0.05, left: width * 0.05, right: width * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Vasudev Krishna",
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: width * 0.05, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Container(
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                      child: Text("to-do",
                          style: GoogleFonts.poppins(
                              fontSize: width * 0.03, color: Colors.black, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const Icon(Icons.settings, color: Colors.white, size: 26),
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
              // Search bar
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
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
                        padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.012),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text("Search",
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              // Filter chips
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
              Text("Future",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: width * 0.045,
                  )),
              const SizedBox(height: 10),
              _buildTaskCard("Doing housework", "7, June, 2023"),
              const SizedBox(height: 10),
              _buildTaskCard("Make a studying plan", "7, June, 2023"),
              const SizedBox(height: 20),
              // Today Task
              Text("Today task",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: width * 0.045,
                  )),
              const SizedBox(height: 10),
              _buildTaskCard("Do groceries", "6, June, 2023"),
              const SizedBox(height: 10),
              _buildTaskCard("Decorate room", "6, June, 2023"),
              const SizedBox(height: 10),
              _buildTaskCard("Prepare music", "6, June, 2023"),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.purple,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30, color: Colors.white),
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
              GestureDetector(
                onTap: () {},
                child: _buildBottomNavItem(Icons.home, "Home", true),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CalendarScreen(tasksPerDay: tasksPerDay)),
                  );
                },
                child: _buildBottomNavItem(Icons.calendar_today, "Calendar", false),
              ),
              const SizedBox(width: 48),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen()));
                },
                child: _buildBottomNavItem(Icons.category, "Category", false),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const Graphscreen()));
                },
                child: _buildBottomNavItem(Icons.show_chart, "Graph", false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---
  static Widget _buildChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.amber : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(label,
            style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.w500)),
      ),
    );
  }

  static Widget _buildTaskCard(String title, String date) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
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
                  Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
                  Text(date, style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const Icon(Icons.flag, color: Colors.red),
        ],
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

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
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
                    tasksPerDay[key] = tasksPerDay[key] != null ? [...tasksPerDay[key]!, task] : [task];
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }
}
