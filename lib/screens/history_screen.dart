import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/activity.dart';

/// Screen for viewing and managing activity history
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Activity> _activities = [];
  List<Activity> _filteredActivities = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _selectedPeriod = 'All Time';

  final List<String> _filterOptions = ['All', 'Transport', 'Food', 'Home Energy', 'Shopping', 'Waste'];
  final List<String> _periodOptions = ['All Time', 'This Week', 'This Month', 'Last 30 Days'];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  /// Load activities from database
  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    
    try {
      _activities = await _databaseService.readAllActivities();
      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading activities: $e')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Apply filters to activities list
  void _applyFilters() {
    List<Activity> filtered = List.from(_activities);

    // Apply type filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((activity) => activity.type == _selectedFilter).toList();
    }

    // Apply period filter
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        filtered = filtered.where((activity) => activity.date.isAfter(weekStart)).toList();
        break;
      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        filtered = filtered.where((activity) => activity.date.isAfter(monthStart)).toList();
        break;
      case 'Last 30 Days':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        filtered = filtered.where((activity) => activity.date.isAfter(thirtyDaysAgo)).toList();
        break;
    }

    setState(() {
      _filteredActivities = filtered;
    });
  }

  /// Handle filter change
  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyFilters();
  }

  /// Handle period change
  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _applyFilters();
  }

  /// Delete activity with confirmation
  Future<void> _deleteActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteActivity(activity.id!);
        await _loadActivities(); // Reload to update the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting activity: $e')),
          );
        }
      }
    }
  }

  /// Show activity details in a modal
  void _showActivityDetails(Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ActivityDetailModal(
        activity: activity,
        onDelete: () {
          Navigator.of(context).pop();
          _deleteActivity(activity);
        },
      ),
    );
  }

  /// Get total footprint for filtered activities
  double get _totalFilteredFootprint {
    return _filteredActivities.fold(0.0, (sum, activity) => sum + activity.carbonFootprint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredActivities.isEmpty
                    ? _buildEmptyState()
                    : _buildActivityList(),
          ),
        ],
      ),
    );
  }

  /// Build summary card showing filtered totals
  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_filteredActivities.length}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text('Activities'),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_totalFilteredFootprint.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text('kg CO₂e'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build filter section
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  onChanged: (value) => _onFilterChanged(value!),
                  decoration: const InputDecoration(
                    labelText: 'Filter by Type',
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _filterOptions.map((filter) {
                    return DropdownMenuItem(value: filter, child: Text(filter));
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPeriod,
                  onChanged: (value) => _onPeriodChanged(value!),
                  decoration: const InputDecoration(
                    labelText: 'Filter by Period',
                    prefixIcon: Icon(Icons.date_range),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _periodOptions.map((period) {
                    return DropdownMenuItem(value: period, child: Text(period));
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No activities found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or log some activities',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedFilter = 'All';
                _selectedPeriod = 'All Time';
              });
              _applyFilters();
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  /// Build activities list
  Widget _buildActivityList() {
    return RefreshIndicator(
      onRefresh: _loadActivities,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredActivities.length,
        itemBuilder: (context, index) {
          final activity = _filteredActivities[index];
          return _buildActivityCard(activity);
        },
      ),
    );
  }

  /// Build individual activity card
  Widget _buildActivityCard(Activity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActivityColor(activity.type),
          child: Icon(
            _getActivityIcon(activity.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          activity.subtype,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${activity.type} • ${activity.value} ${_getUnit(activity)}'),
            Text(
              DateFormat('MMM d, y • h:mm a').format(activity.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${activity.carbonFootprint.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Text(
              'kg CO₂e',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        onTap: () => _showActivityDetails(activity),
      ),
    );
  }

  /// Get color for activity type
  Color _getActivityColor(String type) {
    switch (type) {
      case 'Transport':
        return Colors.blue;
      case 'Food':
        return Colors.orange;
      case 'Home Energy':
        return Colors.green;
      case 'Shopping':
        return Colors.purple;
      case 'Waste':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for activity type
  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'Transport':
        return Icons.directions_car;
      case 'Food':
        return Icons.restaurant;
      case 'Home Energy':
        return Icons.home;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Waste':
        return Icons.delete;
      default:
        return Icons.category;
    }
  }

  /// Get unit for activity (simplified)
  String _getUnit(Activity activity) {
    switch (activity.type) {
      case 'Transport':
        return 'km';
      case 'Food':
        return activity.subtype.contains('Meal') ? 'meal' : 'kg';
      case 'Home Energy':
        return 'kWh';
      case 'Shopping':
        return 'item';
      case 'Waste':
        return 'kg';
      default:
        return '';
    }
  }
}

/// Modal for showing activity details
class ActivityDetailModal extends StatelessWidget {
  final Activity activity;
  final VoidCallback onDelete;

  const ActivityDetailModal({
    super.key,
    required this.activity,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Activity Details',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Activity info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getActivityIcon(activity.type),
                        color: _getActivityColor(activity.type),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity.subtype,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Category', activity.type),
                  _buildDetailRow('Value', '${activity.value} ${_getUnit(activity)}'),
                  _buildDetailRow('Date', DateFormat('MMMM d, y • h:mm a').format(activity.date)),
                  const Divider(),
                  _buildDetailRow(
                    'Carbon Footprint',
                    '${activity.carbonFootprint.toStringAsFixed(2)} kg CO₂e',
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'Transport':
        return Colors.blue;
      case 'Food':
        return Colors.orange;
      case 'Home Energy':
        return Colors.green;
      case 'Shopping':
        return Colors.purple;
      case 'Waste':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'Transport':
        return Icons.directions_car;
      case 'Food':
        return Icons.restaurant;
      case 'Home Energy':
        return Icons.home;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Waste':
        return Icons.delete;
      default:
        return Icons.category;
    }
  }

  String _getUnit(Activity activity) {
    switch (activity.type) {
      case 'Transport':
        return 'km';
      case 'Food':
        return activity.subtype.contains('Meal') ? 'meal' : 'kg';
      case 'Home Energy':
        return 'kWh';
      case 'Shopping':
        return 'item';
      case 'Waste':
        return 'kg';
      default:
        return '';
    }
  }
} 