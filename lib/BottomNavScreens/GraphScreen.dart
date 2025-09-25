
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
    final s = (raw['status'] ?? raw['state'] ?? raw['statusText'] ?? '').toString().toLowerCase();
    if (['done', 'completed'].contains(s)) return 'done';
    if (['missed'].contains(s)) return 'missed';
    return 'future';
  }

  String _weekStartKey(DateTime d) {
    final weekStart = d.subtract(Duration(days: d.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(DateTime(weekStart.year, weekStart.month, weekStart.day));
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
    } catch (_) {}
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final textColorSecondary = theme.textTheme.bodySmall?.color ?? Colors.black54;

    final doneColor = colorScheme.primary;
    final missedColor = colorScheme.error;
    final futureColor = colorScheme.secondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analytics',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: currentUser == null
          ? Center(
              child: Text(
                'Please sign in to view analytics',
                style: GoogleFonts.poppins(color: textColor),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: userTasksRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins(color: textColor)));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                final List<Map<String, dynamic>> tasks = docs.map((d) {
                  final raw = (d.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
                  raw['docId'] = d.id;
                  return raw;
                }).toList();

                final int totalDone = tasks.where((t) => _normalizeStatus(t) == 'done').length;
                final int totalMissed = tasks.where((t) => _normalizeStatus(t) == 'missed').length;
                final int totalFuture = tasks.where((t) => _normalizeStatus(t) == 'future').length;
                final int totalTasks = tasks.length;

                // Group tasks for charts
                final Map<String, Map<String, int>> grouped = {};
                final Map<String, String> labels = {};
                for (var t in tasks) {
                  DateTime? date;
                  try {
                    final dynamic rawDate = t['date'] ?? t['taskDate'] ?? t['createdAt'];
                    if (rawDate is Timestamp) date = rawDate.toDate();
                    else if (rawDate is DateTime) date = rawDate;
                    else if (rawDate is String) date = DateTime.tryParse(rawDate);
                  } catch (_) {
                    date = null;
                  }

                  final status = _normalizeStatus(t);
                  if (date == null) continue;

                  String key;
                  if (_mode == RangeMode.daily) key = DateFormat('yyyy-MM-dd').format(date);
                  else if (_mode == RangeMode.weekly) key = _weekStartKey(date);
                  else key = DateFormat('yyyy-MM').format(date);

                  grouped.putIfAbsent(key, () => {'done': 0, 'missed': 0, 'future': 0});
                  grouped[key]![status] = (grouped[key]![status] ?? 0) + 1;
                  labels[key] = _displayLabel(key, _mode);
                }

                final List<String> sortedKeys = grouped.keys.toList()..sort();
                final int limit = _mode == RangeMode.daily ? 7 : _mode == RangeMode.weekly ? 8 : 6;
                final List<String> recentKeys =
                    sortedKeys.length <= limit ? sortedKeys : sortedKeys.sublist(sortedKeys.length - limit);

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
                      BarChartRodStackItem(0, done, doneColor),
                      BarChartRodStackItem(done, done + missed, missedColor),
                      BarChartRodStackItem(done + missed, total, futureColor),
                    ],
                  );

                  barGroups.add(BarChartGroupData(x: i, barRods: [rod]));
                  lineSpots.add(FlSpot(i.toDouble(), done));
                }

                final double chartMaxY = barGroups.isEmpty
                    ? 1
                    : barGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b) + 1;
                final double maxLineY = lineSpots.isEmpty ? 1 : lineSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Range buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _rangeButton('Daily', RangeMode.daily, doneColor, cardColor, textColor),
                          const SizedBox(width: 8),
                          _rangeButton('Weekly', RangeMode.weekly, doneColor, cardColor, textColor),
                          const SizedBox(width: 8),
                          _rangeButton('Monthly', RangeMode.monthly, doneColor, cardColor, textColor),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Stats cards
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _statCard('Completed', totalDone, doneColor, cardColor, textColorSecondary),
                          _statCard('Missed', totalMissed, missedColor, cardColor, textColorSecondary),
                          _statCard('Pending', totalFuture, futureColor, cardColor, textColorSecondary),
                          _statCard('Total', totalTasks, textColor, cardColor, textColorSecondary),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Pie Chart
                      _buildPieChart(
                        totalDone,
                        totalMissed,
                        totalFuture,
                        doneColor,
                        missedColor,
                        futureColor,
                        cardColor,
                        textColor,
                        textColorSecondary,
                        totalTasks,
                      ),
                      const SizedBox(height: 18),
                      // Bar Chart
                      _buildBarChart(barGroups, recentKeys, labels, chartMaxY, width, cardColor, textColor),
                      const SizedBox(height: 18),
                      // Line Chart
                      _buildLineChart(lineSpots, recentKeys, labels, maxLineY, cardColor, textColor, doneColor),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Tip: long-press tasks on Home to mark done and see live updates.',
                          style: GoogleFonts.poppins(color: textColorSecondary, fontSize: 12),
                        ),
                      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(label,
            style: GoogleFonts.poppins(color: selected ? Colors.black : textColor, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _statCard(String title, int value, Color valueColor, Color cardColor, Color textColor) {
    return SizedBox(
      width: 140,
      child: Card(
        elevation: 3,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(color: textColor, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value.toString(),
                    style: GoogleFonts.poppins(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
                Icon(Icons.show_chart, color: valueColor, size: 20),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, int value, Color textColor) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.poppins(color: textColor))),
        Text(value.toString(), style: GoogleFonts.poppins(color: textColor)),
      ],
    );
  }

  Widget _buildPieChart(int done, int missed, int future, Color doneColor, Color missedColor, Color futureColor,
      Color cardColor, Color textColor, Color textColorSecondary, int totalTasks) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3)),
      ]),
      padding: const EdgeInsets.all(16),
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
                  PieChartSectionData(value: done.toDouble(), color: doneColor, title: done == 0 ? '' : done.toString()),
                  PieChartSectionData(value: missed.toDouble(), color: missedColor, title: missed == 0 ? '' : missed.toString()),
                  PieChartSectionData(value: future.toDouble(), color: futureColor, title: future == 0 ? '' : future.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow(doneColor, 'Completed', done, textColor),
                const SizedBox(height: 6),
                _legendRow(missedColor, 'Missed', missed, textColor),
                const SizedBox(height: 6),
                _legendRow(futureColor, 'Pending', future, textColor),
                const SizedBox(height: 10),
                Text('Total tasks: $totalTasks', style: GoogleFonts.poppins(color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<BarChartGroupData> barGroups, List<String> recentKeys, Map<String, String> labels,
      double chartMaxY, double width, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3)),
      ]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Activity', style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: barGroups.isEmpty
              ? Center(child: Text('No data for selected range', style: GoogleFonts.poppins(color: textColor)))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: chartMaxY,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= recentKeys.length) return const SizedBox.shrink();
                            final label = labels[recentKeys[idx]] ?? recentKeys[idx];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(label, style: GoogleFonts.poppins(color: textColor, fontSize: 10)),
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
      ]),
    );
  }

  Widget _buildLineChart(List<FlSpot> lineSpots, List<String> recentKeys, Map<String, String> labels, double maxLineY,
      Color cardColor, Color textColor, Color lineColor) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3)),
      ]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Completion trend', style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: lineSpots.isEmpty
              ? Center(child: Text('No trend data', style: GoogleFonts.poppins(color: textColor)))
              : LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxLineY,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, interval: 1),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= recentKeys.length) return const SizedBox.shrink();
                            final label = labels[recentKeys[idx]] ?? recentKeys[idx];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(label, style: GoogleFonts.poppins(color: textColor, fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: lineSpots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
        ),
      ]),
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
    final s = (raw['status'] ?? raw['state'] ?? raw['statusText'] ?? '').toString().toLowerCase();
    if (['done', 'completed'].contains(s)) return 'done';
    if (['missed'].contains(s)) return 'missed';
    return 'future';
  }

  String _weekStartKey(DateTime d) {
    final weekStart = d.subtract(Duration(days: d.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(DateTime(weekStart.year, weekStart.month, weekStart.day));
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
    } catch (_) {}
    return key;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final textColorSecondary = theme.textTheme.bodySmall?.color ?? Colors.black54;

    final doneColor = colorScheme.primary;
    final missedColor = colorScheme.error;
    final futureColor = colorScheme.secondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analytics',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: currentUser == null
          ? Center(
              child: Text(
                'Please sign in to view analytics',
                style: GoogleFonts.poppins(color: textColor),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: userTasksRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins(color: textColor)));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                final List<Map<String, dynamic>> tasks = docs.map((d) {
                  final raw = (d.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
                  raw['docId'] = d.id;
                  return raw;
                }).toList();

                // Ensure status counts are accurate
                final int totalDone = tasks.where((t) => _normalizeStatus(t) == 'done').length;
                final int totalMissed = tasks.where((t) => _normalizeStatus(t) == 'missed').length;
                final int totalFuture = tasks.where((t) => _normalizeStatus(t) == 'future').length;
                final int totalTasks = tasks.length;

                // Group tasks for charts
                final Map<String, Map<String, int>> grouped = {};
                final Map<String, String> labels = {};
                for (var t in tasks) {
                  DateTime? date;
                  try {
                    final dynamic rawDate = t['date'] ?? t['taskDate'] ?? t['createdAt'];
                    if (rawDate is Timestamp) date = rawDate.toDate();
                    else if (rawDate is DateTime) date = rawDate;
                    else if (rawDate is String) date = DateTime.tryParse(rawDate);
                  } catch (_) {
                    date = null;
                  }

                  final status = _normalizeStatus(t);
                  if (date == null) continue;

                  String key;
                  if (_mode == RangeMode.daily) key = DateFormat('yyyy-MM-dd').format(date);
                  else if (_mode == RangeMode.weekly) key = _weekStartKey(date);
                  else key = DateFormat('yyyy-MM').format(date);

                  grouped.putIfAbsent(key, () => {'done': 0, 'missed': 0, 'future': 0});
                  grouped[key]![status] = (grouped[key]![status] ?? 0) + 1;
                  labels[key] = _displayLabel(key, _mode);
                }

                final List<String> sortedKeys = grouped.keys.toList()..sort();
                final int limit = _mode == RangeMode.daily ? 7 : _mode == RangeMode.weekly ? 8 : 6;
                final List<String> recentKeys =
                    sortedKeys.length <= limit ? sortedKeys : sortedKeys.sublist(sortedKeys.length - limit);

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
                      BarChartRodStackItem(0, done, doneColor),
                      BarChartRodStackItem(done, done + missed, missedColor),
                      BarChartRodStackItem(done + missed, total, futureColor),
                    ],
                  );

                  barGroups.add(BarChartGroupData(x: i, barRods: [rod]));
                  lineSpots.add(FlSpot(i.toDouble(), done));
                }

                final double chartMaxY = barGroups.isEmpty
                    ? 1
                    : barGroups.map((g) => g.barRods.first.toY).reduce((a, b) => a > b ? a : b) + 1;
                final double maxLineY = lineSpots.isEmpty ? 1 : lineSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _rangeButton('Daily', RangeMode.daily, doneColor, cardColor, textColor),
                          const SizedBox(width: 8),
                          _rangeButton('Weekly', RangeMode.weekly, doneColor, cardColor, textColor),
                          const SizedBox(width: 8),
                          _rangeButton('Monthly', RangeMode.monthly, doneColor, cardColor, textColor),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _statCard('Completed', totalDone, doneColor, cardColor, textColorSecondary),
                          _statCard('Missed', totalMissed, missedColor, cardColor, textColorSecondary),
                          _statCard('Pending', totalFuture, futureColor, cardColor, textColorSecondary),
                          _statCard('Total', totalTasks, textColor, cardColor, textColorSecondary),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _buildPieChart(
                        totalDone,
                        totalMissed,
                        totalFuture,
                        doneColor,
                        missedColor,
                        futureColor,
                        cardColor,
                        textColor,
                        textColorSecondary,
                        totalTasks,
                      ),
                      const SizedBox(height: 18),
                      _buildBarChart(barGroups, recentKeys, labels, chartMaxY, width, cardColor, textColor),
                      const SizedBox(height: 18),
                      _buildLineChart(lineSpots, recentKeys, labels, maxLineY, cardColor, textColor, doneColor),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Tip: long-press tasks on Home to mark done and see live updates.',
                          style: GoogleFonts.poppins(color: textColorSecondary, fontSize: 12),
                        ),
                      ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent : card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(label,
            style: GoogleFonts.poppins(color: selected ? Colors.black : textColor, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _statCard(String title, int value, Color valueColor, Color cardColor, Color textColor) {
    return SizedBox(
      width: 140,
      child: Card(
        elevation: 3,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(color: textColor, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value.toString(),
                    style: GoogleFonts.poppins(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
                Icon(Icons.show_chart, color: valueColor, size: 20),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, int value, Color textColor) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.poppins(color: textColor))),
        Text(value.toString(), style: GoogleFonts.poppins(color: textColor)),
      ],
    );
  }

  Widget _buildPieChart(int done, int missed, int future, Color doneColor, Color missedColor, Color futureColor,
      Color cardColor, Color textColor, Color textColorSecondary, int totalTasks) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3)),
      ]),
      padding: const EdgeInsets.all(16),
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
                  PieChartSectionData(value: done.toDouble(), color: doneColor, title: done == 0 ? '' : done.toString()),
                  PieChartSectionData(value: missed.toDouble(), color: missedColor, title: missed == 0 ? '' : missed.toString()),
                  PieChartSectionData(value: future.toDouble(), color: futureColor, title: future == 0 ? '' : future.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendRow(doneColor, 'Completed', done, textColor),
                const SizedBox(height: 6),
                _legendRow(missedColor, 'Missed', missed, textColor),
                const SizedBox(height: 6),
                _legendRow(futureColor, 'Pending', future, textColor),
                const SizedBox(height: 10),
                Text('Total tasks: $totalTasks', style: GoogleFonts.poppins(color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<BarChartGroupData> barGroups, List<String> recentKeys, Map<String, String> labels,
      double chartMaxY, double width, Color cardColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3)),
      ]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Activity', style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: barGroups.isEmpty
              ? Center(child: Text('No data for selected range', style: GoogleFonts.poppins(color: textColor)))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: chartMaxY,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= recentKeys.length) return const SizedBox.shrink();
                            final label = labels[recentKeys[idx]] ?? recentKeys[idx];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(label, style: GoogleFonts.poppins(color: textColor, fontSize: 10)),
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
      ]),
    );
  }

  Widget _buildLineChart(List<FlSpot> lineSpots, List<String> recentKeys, Map<String, String> labels, double maxLineY,
      Color cardColor, Color textColor, Color lineColor) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 3)),
      ]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Completion trend', style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: lineSpots.isEmpty
              ? Center(child: Text('No trend data', style: GoogleFonts.poppins(color: textColor)))
              : LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxLineY,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, interval: 1),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= recentKeys.length) return const SizedBox.shrink();
                            final label = labels[recentKeys[idx]] ?? recentKeys[idx];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(label, style: GoogleFonts.poppins(color: textColor, fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: lineSpots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }
}
