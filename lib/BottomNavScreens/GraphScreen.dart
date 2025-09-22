/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

enum RangeMode { daily, weekly, monthly }

class Graphscreen extends StatefulWidget {
  const Graphscreen({super.key});

  @override
  State<Graphscreen> createState() => _GraphscreenState();
}

class _GraphscreenState extends State<Graphscreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final CollectionReference userTasksRef;
  RangeMode _mode = RangeMode.daily;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      userTasksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks');
    }
  }

  String _normalizeStatus(Map<String, dynamic> raw) {
    final dynamic s = raw['status'] ?? raw['state'] ?? raw['statusText'];
    final status = (s ?? '').toString().toLowerCase();
    if (status == 'done' || status == 'completed') return 'done';
    if (status == 'missed') return 'missed';
    return 'future';
  }

  String _weekStartKey(DateTime d) {
    final weekStart = d.subtract(Duration(days: d.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(
        DateTime(weekStart.year, weekStart.month, weekStart.day));
  }

  String _displayLabel(String key, RangeMode mode) {
    try {
      if (mode == RangeMode.daily) {
        final d = DateTime.parse(key);
        return DateFormat('d MMM').format(d);
      }
      if (mode == RangeMode.weekly) {
        final d = DateTime.parse(key);
        return 'Week of ${DateFormat('d MMM').format(d)}';
      }
      if (mode == RangeMode.monthly) {
        final parts = key.split('-');
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return DateFormat('MMM yyyy').format(DateTime(y, m));
      }
    } catch (e) {
      return key;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
  backgroundColor: Colors.black,
  appBar: AppBar(
    backgroundColor: Colors.black,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white), // white arrow
      onPressed: () {
        Navigator.pop(context);
      },
    ),
    title: Text(
      'Analytics',
      style: GoogleFonts.poppins(
        color: Colors.white, // white text
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
      body: currentUser == null
          ? Center(
              child: Text('Please sign in to view analytics',
                  style: GoogleFonts.poppins(color: Colors.white)),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: userTasksRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: GoogleFonts.poppins(color: Colors.white)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final List<Map<String, dynamic>> tasks = docs.map((d) {
                  final raw =
                      (d.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
                  raw['docId'] = d.id;
                  return raw;
                }).toList();

                final int totalDone =
                    tasks.where((t) => _normalizeStatus(t) == 'done').length;
                final int totalMissed =
                    tasks.where((t) => _normalizeStatus(t) == 'missed').length;
                final int totalFuture =
                    tasks.where((t) => _normalizeStatus(t) == 'future').length;
                final int totalTasks = tasks.length;

                final Map<String, Map<String, int>> grouped = {};
                final Map<String, String> labels = {};
                for (var t in tasks) {
                  DateTime? date;
                  try {
                    final dynamic rawDate =
                        t['date'] ?? t['taskDate'] ?? t['createdAt'];
                    if (rawDate is Timestamp) {
                      date = rawDate.toDate();
                    } else if (rawDate is DateTime) {
                      date = rawDate;
                    } else if (rawDate is String) {
                      date = DateTime.tryParse(rawDate);
                    }
                  } catch (e) {
                    date = null;
                  }

                  final status = _normalizeStatus(t);
                  if (date == null) continue;

                  String key;
                  if (_mode == RangeMode.daily) {
                    key = DateFormat('yyyy-MM-dd').format(date);
                  } else if (_mode == RangeMode.weekly) {
                    key = _weekStartKey(date);
                  } else {
                    key = DateFormat('yyyy-MM').format(date);
                  }

                  grouped.putIfAbsent(
                      key, () => {'done': 0, 'missed': 0, 'future': 0});
                  grouped[key]![status] = (grouped[key]![status] ?? 0) + 1;
                  labels[key] = _displayLabel(key, _mode);
                }

                final List<String> sortedKeys = grouped.keys.toList()..sort();
                final int limit = _mode == RangeMode.daily
                    ? 7
                    : _mode == RangeMode.weekly
                        ? 8
                        : 6;
                final List<String> recentKeys = sortedKeys.length <= limit
                    ? sortedKeys
                    : sortedKeys.sublist(sortedKeys.length - limit);

                final List<BarChartGroupData> barGroups = [];
                final List<FlSpot> lineSpots = [];

                for (int i = 0; i < recentKeys.length; i++) {
                  final k = recentKeys[i];
                  final map = grouped[k]!;
                  final double done = (map['done'] ?? 0).toDouble();
                  final double missed = (map['missed'] ?? 0).toDouble();
                  final double future = (map['future'] ?? 0).toDouble();
                  final double total = done + missed + future;

                  final rod = BarChartRodData(
                    toY: total > 0 ? total : 0.0,
                    width: (width / (limit * 3)).clamp(8, 24).toDouble(),
                    borderRadius: BorderRadius.circular(6),
                    rodStackItems: [
                      BarChartRodStackItem(0, done, Colors.green),
                      BarChartRodStackItem(done, done + missed, Colors.red),
                      BarChartRodStackItem(
                          done + missed, total, Colors.amber),
                    ],
                  );

                  barGroups.add(BarChartGroupData(x: i, barRods: [rod]));
                  lineSpots.add(FlSpot(i.toDouble(), done));
                }

                final double maxBarY = barGroups.isEmpty
                    ? 3
                    : barGroups
                        .map((g) => g.barRods.first.toY)
                        .reduce((a, b) => a > b ? a : b);
                final double chartMaxY = maxBarY > 0 ? maxBarY + 1 : 3;
                final double maxLineY = lineSpots.isEmpty
                    ? 3
                    : lineSpots
                            .map((s) => s.y)
                            .reduce((a, b) => a > b ? a : b) +
                        1;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _rangeButton('Daily', RangeMode.daily),
                          const SizedBox(width: 8),
                          _rangeButton('Weekly', RangeMode.weekly),
                          const SizedBox(width: 8),
                          _rangeButton('Monthly', RangeMode.monthly),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _statCard('Completed', totalDone, Colors.green),
                          _statCard('Missed', totalMissed, Colors.red),
                          _statCard('Pending', totalFuture, Colors.amber),
                          _statCard('Total', totalTasks, Colors.white70),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 28,
                                  sections: [
                                    PieChartSectionData(
                                        value: totalDone.toDouble(),
                                        color: Colors.green,
                                        title: totalDone == 0
                                            ? ''
                                            : totalDone.toString()),
                                    PieChartSectionData(
                                        value: totalMissed.toDouble(),
                                        color: Colors.red,
                                        title: totalMissed == 0
                                            ? ''
                                            : totalMissed.toString()),
                                    PieChartSectionData(
                                        value: totalFuture.toDouble(),
                                        color: Colors.amber,
                                        title: totalFuture == 0
                                            ? ''
                                            : totalFuture.toString()),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _legendRow(Colors.green, 'Completed',
                                      totalDone),
                                  const SizedBox(height: 6),
                                  _legendRow(Colors.red, 'Missed', totalMissed),
                                  const SizedBox(height: 6),
                                  _legendRow(
                                      Colors.amber, 'Pending', totalFuture),
                                  const SizedBox(height: 8),
                                  Text('Total tasks: $totalTasks',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Activity',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 220,
                              child: barGroups.isEmpty
                                  ? Center(
                                      child: Text('No data for selected range',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white)))
                                  : BarChart(
                                      BarChartData(
                                        alignment:
                                            BarChartAlignment.spaceAround,
                                        maxY: chartMaxY,
                                        barTouchData:
                                            BarTouchData(enabled: true),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 30,
                                                interval: 1),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (val, meta) {
                                                final idx = val.toInt();
                                                if (idx < 0 ||
                                                    idx >= recentKeys.length) {
                                                  return const SizedBox
                                                      .shrink();
                                                }
                                                final label =
                                                    labels[recentKeys[idx]] ??
                                                        recentKeys[idx];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Text(label,
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: Colors
                                                                  .white,
                                                              fontSize: 10)),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        gridData: FlGridData(show: true),
                                        barGroups: barGroups,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Completion trend',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 180,
                              child: lineSpots.isEmpty
                                  ? Center(
                                      child: Text('No trend data',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white)))
                                  : LineChart(
                                      LineChartData(
                                        minY: 0,
                                        maxY: maxLineY,
                                        gridData: FlGridData(show: true),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: true, interval: 1),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (val, meta) {
                                                final idx = val.toInt();
                                                if (idx < 0 ||
                                                    idx >= recentKeys.length) {
                                                  return const SizedBox
                                                      .shrink();
                                                }
                                                final label =
                                                    labels[recentKeys[idx]] ??
                                                        recentKeys[idx];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 8.0),
                                                  child: Text(label,
                                                      style:
                                                          GoogleFonts.poppins(
                                                              color: Colors
                                                                  .white,
                                                              fontSize: 10)),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: lineSpots,
                                            isCurved: true,
                                            barWidth: 3,
                                            dotData: FlDotData(show: true),
                                            color: Colors.green,
                                          )
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Tip: long-press tasks on Home to mark done and see live updates.',
                          style: GoogleFonts.poppins(
                              color: Colors.grey, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _rangeButton(String label, RangeMode mode) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: selected ? Colors.amber : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: selected ? Colors.black : Colors.white)),
      ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return SizedBox(
      width: 140,
      child: Card(
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(value.toString(),
                      style: GoogleFonts.poppins(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.show_chart, color: color)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, int value) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label, style: GoogleFonts.poppins(color: Colors.white))),
        Text(value.toString(), style: GoogleFonts.poppins(color: Colors.white)),
      ],
    );
  }
}

*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

enum RangeMode { daily, weekly, monthly }

class Graphscreen extends StatefulWidget {
  const Graphscreen({super.key});

  @override
  State<Graphscreen> createState() => _GraphscreenState();
}

class _GraphscreenState extends State<Graphscreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final CollectionReference userTasksRef;
  RangeMode _mode = RangeMode.daily;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      userTasksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks');
    }
  }

  String _normalizeStatus(Map<String, dynamic> raw) {
    final dynamic s = raw['status'] ?? raw['state'] ?? raw['statusText'];
    final status = (s ?? '').toString().toLowerCase();
    if (status == 'done' || status == 'completed') return 'done';
    if (status == 'missed') return 'missed';
    return 'future';
  }

  String _weekStartKey(DateTime d) {
    final weekStart = d.subtract(Duration(days: d.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(
        DateTime(weekStart.year, weekStart.month, weekStart.day));
  }

  String _displayLabel(String key, RangeMode mode) {
    try {
      if (mode == RangeMode.daily) {
        final d = DateTime.parse(key);
        return DateFormat('d MMM').format(d);
      }
      if (mode == RangeMode.weekly) {
        final d = DateTime.parse(key);
        return 'Week of ${DateFormat('d MMM').format(d)}';
      }
      if (mode == RangeMode.monthly) {
        final parts = key.split('-');
        final y = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        return DateFormat('MMM yyyy').format(DateTime(y, m));
      }
    } catch (e) {
      return key;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic colors
    final bgColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;
    final accentColor = const Color(0xFF6A5AE0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Analytics',
            style: GoogleFonts.poppins(
                color: textColor, fontWeight: FontWeight.w600)),
      ),
      body: currentUser == null
          ? Center(
              child: Text('Please sign in to view analytics',
                  style: GoogleFonts.poppins(color: textColor)),
            )
          : StreamBuilder<QuerySnapshot>(
              stream:
                  userTasksRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: GoogleFonts.poppins(color: textColor)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final List<Map<String, dynamic>> tasks = docs.map((d) {
                  final raw =
                      (d.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
                  raw['docId'] = d.id;
                  return raw;
                }).toList();

                final int totalDone =
                    tasks.where((t) => _normalizeStatus(t) == 'done').length;
                final int totalMissed =
                    tasks.where((t) => _normalizeStatus(t) == 'missed').length;
                final int totalFuture =
                    tasks.where((t) => _normalizeStatus(t) == 'future').length;
                final int totalTasks = tasks.length;

                final Map<String, Map<String, int>> grouped = {};
                final Map<String, String> labels = {};
                for (var t in tasks) {
                  DateTime? date;
                  try {
                    final dynamic rawDate =
                        t['date'] ?? t['taskDate'] ?? t['createdAt'];
                    if (rawDate is Timestamp) {
                      date = rawDate.toDate();
                    } else if (rawDate is DateTime) {
                      date = rawDate;
                    } else if (rawDate is String) {
                      date = DateTime.tryParse(rawDate);
                    }
                  } catch (e) {
                    date = null;
                  }

                  final status = _normalizeStatus(t);
                  if (date == null) continue;

                  String key;
                  if (_mode == RangeMode.daily) {
                    key = DateFormat('yyyy-MM-dd').format(date);
                  } else if (_mode == RangeMode.weekly) {
                    key = _weekStartKey(date);
                  } else {
                    key = DateFormat('yyyy-MM').format(date);
                  }

                  grouped.putIfAbsent(
                      key, () => {'done': 0, 'missed': 0, 'future': 0});
                  grouped[key]![status] = (grouped[key]![status] ?? 0) + 1;
                  labels[key] = _displayLabel(key, _mode);
                }

                final List<String> sortedKeys = grouped.keys.toList()..sort();
                final int limit = _mode == RangeMode.daily
                    ? 7
                    : _mode == RangeMode.weekly
                        ? 8
                        : 6;
                final List<String> recentKeys = sortedKeys.length <= limit
                    ? sortedKeys
                    : sortedKeys.sublist(sortedKeys.length - limit);

                final List<BarChartGroupData> barGroups = [];
                final List<FlSpot> lineSpots = [];

                for (int i = 0; i < recentKeys.length; i++) {
                  final k = recentKeys[i];
                  final map = grouped[k]!;
                  final double done = (map['done'] ?? 0).toDouble();
                  final double missed = (map['missed'] ?? 0).toDouble();
                  final double future = (map['future'] ?? 0).toDouble();
                  final double total = done + missed + future;

                  final rod = BarChartRodData(
                    toY: total > 0 ? total : 0.0,
                    width: (width / (limit * 3)).clamp(8, 24).toDouble(),
                    borderRadius: BorderRadius.circular(6),
                    rodStackItems: [
                      BarChartRodStackItem(0, done, Colors.green),
                      BarChartRodStackItem(done, done + missed, Colors.red),
                      BarChartRodStackItem(done + missed, total, Colors.amber),
                    ],
                  );

                  barGroups.add(BarChartGroupData(x: i, barRods: [rod]));
                  lineSpots.add(FlSpot(i.toDouble(), done));
                }

                final double chartMaxY = barGroups.isEmpty
                    ? 1
                    : barGroups
                            .map((g) => g.barRods.first.toY)
                            .reduce((a, b) => a > b ? a : b)
                            .clamp(1, double.infinity) +
                        1;

                final double maxLineY = lineSpots.isEmpty
                    ? 1
                    : lineSpots
                            .map((s) => s.y)
                            .reduce((a, b) => a > b ? a : b)
                            .clamp(1, double.infinity) +
                        1;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _rangeButton('Daily', RangeMode.daily, accentColor, cardColor, textColor),
                          const SizedBox(width: 8),
                          _rangeButton('Weekly', RangeMode.weekly, accentColor, cardColor, textColor),
                          const SizedBox(width: 8),
                          _rangeButton('Monthly', RangeMode.monthly, accentColor, cardColor, textColor),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _statCard('Completed', totalDone, Colors.green, cardColor, textColorSecondary),
                          _statCard('Missed', totalMissed, Colors.red, cardColor, textColorSecondary),
                          _statCard('Pending', totalFuture, Colors.amber, cardColor, textColorSecondary),
                          _statCard('Total', totalTasks, textColor, cardColor, textColorSecondary),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 28,
                                  sections: [
                                    PieChartSectionData(
                                        value: totalDone.toDouble(),
                                        color: Colors.green,
                                        title: totalDone == 0
                                            ? ''
                                            : totalDone.toString()),
                                    PieChartSectionData(
                                        value: totalMissed.toDouble(),
                                        color: Colors.red,
                                        title: totalMissed == 0
                                            ? ''
                                            : totalMissed.toString()),
                                    PieChartSectionData(
                                        value: totalFuture.toDouble(),
                                        color: Colors.amber,
                                        title: totalFuture == 0
                                            ? ''
                                            : totalFuture.toString()),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _legendRow(Colors.green, 'Completed', totalDone, textColor),
                                  const SizedBox(height: 6),
                                  _legendRow(Colors.red, 'Missed', totalMissed, textColor),
                                  const SizedBox(height: 6),
                                  _legendRow(Colors.amber, 'Pending', totalFuture, textColor),
                                  const SizedBox(height: 8),
                                  Text('Total tasks: $totalTasks',
                                      style: GoogleFonts.poppins(color: textColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Activity',
                                style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 220,
                              child: barGroups.isEmpty
                                  ? Center(
                                      child: Text('No data for selected range',
                                          style: GoogleFonts.poppins(
                                              color: textColor)))
                                  : BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: chartMaxY,
                                        barTouchData: BarTouchData(enabled: true),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: true,
                                                reservedSize: 30,
                                                interval: 1),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (val, meta) {
                                                final idx = val.toInt();
                                                if (idx < 0 ||
                                                    idx >= recentKeys.length) {
                                                  return const SizedBox.shrink();
                                                }
                                                final label =
                                                    labels[recentKeys[idx]] ??
                                                        recentKeys[idx];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(top: 8.0),
                                                  child: Text(label,
                                                      style: GoogleFonts.poppins(
                                                          color: textColor,
                                                          fontSize: 10)),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        gridData: FlGridData(show: true),
                                        barGroups: barGroups,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Completion trend',
                                style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 180,
                              child: lineSpots.isEmpty
                                  ? Center(
                                      child: Text('No trend data',
                                          style: GoogleFonts.poppins(
                                              color: textColor)))
                                  : LineChart(
                                      LineChartData(
                                        minY: 0,
                                        maxY: maxLineY,
                                        gridData: FlGridData(show: true),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: true, interval: 1),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (val, meta) {
                                                final idx = val.toInt();
                                                if (idx < 0 ||
                                                    idx >= recentKeys.length) {
                                                  return const SizedBox.shrink();
                                                }
                                                final label =
                                                    labels[recentKeys[idx]] ??
                                                        recentKeys[idx];
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(top: 8.0),
                                                  child: Text(label,
                                                      style: GoogleFonts.poppins(
                                                          color: textColor,
                                                          fontSize: 10)),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: lineSpots,
                                            isCurved: true,
                                            barWidth: 3,
                                            dotData: FlDotData(show: true),
                                            color: Colors.green,
                                          )
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Tip: long-press tasks on Home to mark done and see live updates.',
                          style: GoogleFonts.poppins(
                              color: Colors.grey, fontSize: 12),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _rangeButton(String label, RangeMode mode, Color accent, Color card, Color textColor) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: selected ? accent : card,
            borderRadius: BorderRadius.circular(8)),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: selected ? Colors.black : textColor)),
      ),
    );
  }

  Widget _statCard(String title, int value, Color valueColor, Color cardColor, Color textColor) {
    return SizedBox(
      width: 140,
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(color: textColor, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(value.toString(),
                      style: GoogleFonts.poppins(
                          color: valueColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.show_chart, color: valueColor)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, int value, Color textColor) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.poppins(color: textColor))),
        Text(value.toString(), style: GoogleFonts.poppins(color: textColor)),
      ],
    );
  }
}
