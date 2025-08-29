import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';

/// Dashboard screen showing carbon footprint summary and visualization
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _databaseService = DatabaseService();
  double _totalFootprint = 0.0;
  double _weeklyFootprint = 0.0;
  double _monthlyFootprint = 0.0;
  Map<DateTime, double> _dailyData = {};
  Map<String, double> _categoryData = {};
  bool _isLoading = true;
  String _selectedPeriod = 'Week';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  /// Load all dashboard data
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      await _loadFootprintSummary();
      await _loadDailyData();
      await _loadCategoryData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Load footprint summary for different periods
  Future<void> _loadFootprintSummary() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    _totalFootprint = await _databaseService.getTotalCarbonFootprint();
    _weeklyFootprint = await _databaseService.getTotalCarbonFootprint(
      start: weekStart,
      end: now,
    );
    _monthlyFootprint = await _databaseService.getTotalCarbonFootprint(
      start: monthStart,
      end: now,
    );
  }

  /// Load daily data for chart
  Future<void> _loadDailyData() async {
    final now = DateTime.now();
    DateTime startDate;

    if (_selectedPeriod == 'Week') {
      startDate = now.subtract(const Duration(days: 7));
    } else {
      startDate = now.subtract(const Duration(days: 30));
    }

    _dailyData = await _databaseService.getDailyCarbonFootprint(
      start: startDate,
      end: now,
    );
  }

  /// Load category breakdown data
  Future<void> _loadCategoryData() async {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));

    _categoryData = await _databaseService.getCarbonFootprintByType(
      start: startDate,
      end: now,
    );
  }

  /// Get motivational message based on carbon footprint
  String _getMotivationalMessage() {
    if (_weeklyFootprint == 0) {
      return "🌱 Start tracking your carbon footprint today!";
    } else if (_weeklyFootprint < 50) {
      return "🌟 Excellent! You're living sustainably!";
    } else if (_weeklyFootprint < 100) {
      return "👍 Good job! Keep up the green habits!";
    } else if (_weeklyFootprint < 200) {
      return "💡 You're doing okay. Let's reduce more!";
    } else {
      return "⚡ Time to make some eco-friendly changes!";
    }
  }

  /// Get progress value (0.0 to 1.0) based on weekly target
  double _getProgressValue() {
    const double weeklyTarget = 100.0; // kg CO2e
    return (_weeklyFootprint / weeklyTarget).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carbon Footprint Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 16),
                    _buildMotivationalSection(),
                    const SizedBox(height: 16),
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),
                    _buildDailyChart(),
                    const SizedBox(height: 16),
                    _buildCategoryChart(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build summary cards showing total footprints
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total',
            _totalFootprint,
            Icons.public,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'This Week',
            _weeklyFootprint,
            Icons.calendar_view_week,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'This Month',
            _monthlyFootprint,
            Icons.calendar_month,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  /// Build individual summary card
  Widget _buildSummaryCard(
      String title, double value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
            Text(
              'CO₂e',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build motivational section with progress indicator
  Widget _buildMotivationalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _getMotivationalMessage(),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Weekly Progress (Target: 100 kg CO₂e)',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _getProgressValue(),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressValue() <= 1.0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_weeklyFootprint.toStringAsFixed(1)} / 100 kg CO₂e',
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build period selector for chart
  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Week', label: Text('7 Days')),
            ButtonSegment(value: 'Month', label: Text('30 Days')),
          ],
          selected: {_selectedPeriod},
          onSelectionChanged: (Set<String> selected) {
            setState(() {
              _selectedPeriod = selected.first;
            });
            _loadDailyData();
          },
        ),
      ],
    );
  }

  /// Build daily carbon footprint chart
  Widget _buildDailyChart() {
    if (_dailyData.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text('No data available for the selected period'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Daily Carbon Footprint',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          return Text(
                            DateFormat('M/d').format(date),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dailyData.entries
                          .map((entry) => FlSpot(
                                entry.key.millisecondsSinceEpoch.toDouble(),
                                entry.value,
                              ))
                          .toList(),
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build category breakdown pie chart
  Widget _buildCategoryChart() {
    if (_categoryData.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: const Center(
            child: Text('No category data available'),
          ),
        ),
      );
    }

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Carbon Footprint by Category (Last 30 Days)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: _categoryData.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                          final index = entry.key;
                          final categoryEntry = entry.value;
                          return PieChartSectionData(
                            color: colors[index % colors.length],
                            value: categoryEntry.value,
                            title: '${categoryEntry.value.toStringAsFixed(1)}',
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            radius: 50,
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _categoryData.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final categoryEntry = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: colors[index % colors.length],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  categoryEntry.key,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
