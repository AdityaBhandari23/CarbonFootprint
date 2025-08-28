import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/carbon_factors_service.dart';
import '../models/activity.dart';
import '../models/carbon_factor.dart';

/// Screen for logging new carbon footprint activities
class LogActivityScreen extends StatefulWidget {
  const LogActivityScreen({super.key});

  @override
  State<LogActivityScreen> createState() => _LogActivityScreenState();
}

class _LogActivityScreenState extends State<LogActivityScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final CarbonFactorsService _carbonFactorsService = CarbonFactorsService();
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();

  String? _selectedType;
  String? _selectedSubtype;
  DateTime _selectedDate = DateTime.now();
  double _calculatedFootprint = 0.0;
  CarbonFactor? _currentFactor;
  bool _isLoading = false;

  List<String> _availableTypes = [];
  List<String> _availableSubtypes = [];

  @override
  void initState() {
    super.initState();
    _loadActivityTypes();
    _valueController.addListener(_calculateFootprint);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  /// Load available activity types from carbon factors
  void _loadActivityTypes() {
    if (_carbonFactorsService.isLoaded) {
      setState(() {
        _availableTypes = _carbonFactorsService.getAvailableTypes();
      });
    }
  }

  /// Handle activity type selection
  void _onTypeSelected(String? type) {
    setState(() {
      _selectedType = type;
      _selectedSubtype = null;
      _availableSubtypes = type != null 
          ? _carbonFactorsService.getSubtypesForType(type)
          : [];
      _calculatedFootprint = 0.0;
      _currentFactor = null;
    });
  }

  /// Handle activity subtype selection
  void _onSubtypeSelected(String? subtype) {
    setState(() {
      _selectedSubtype = subtype;
      if (_selectedType != null && subtype != null) {
        _currentFactor = _carbonFactorsService.getFactorForActivity(
          _selectedType!,
          subtype,
        );
      }
      _calculateFootprint();
    });
  }

  /// Calculate carbon footprint in real-time
  void _calculateFootprint() {
    if (_currentFactor != null && _valueController.text.isNotEmpty) {
      final value = double.tryParse(_valueController.text);
      if (value != null && value > 0) {
        setState(() {
          _calculatedFootprint = _currentFactor!.factor * value;
        });
      } else {
        setState(() {
          _calculatedFootprint = 0.0;
        });
      }
    } else {
      setState(() {
        _calculatedFootprint = 0.0;
      });
    }
  }

  /// Save the activity to database
  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == null || _selectedSubtype == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both activity type and subtype')),
      );
      return;
    }

    final value = double.tryParse(_valueController.text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive value')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final activity = Activity(
        type: _selectedType!,
        subtype: _selectedSubtype!,
        value: value,
        carbonFootprint: _calculatedFootprint,
        date: _selectedDate,
      );

      await _databaseService.createActivity(activity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving activity: $e')),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Reset the form to initial state
  void _resetForm() {
    setState(() {
      _selectedType = null;
      _selectedSubtype = null;
      _selectedDate = DateTime.now();
      _calculatedFootprint = 0.0;
      _currentFactor = null;
      _availableSubtypes = [];
    });
    _valueController.clear();
    _formKey.currentState?.reset();
  }

  /// Show date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Activity'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Reset form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInstructionCard(),
              const SizedBox(height: 16),
              _buildFormCard(),
              const SizedBox(height: 16),
              _buildCalculationCard(),
              const SizedBox(height: 24),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build instruction card
  Widget _buildInstructionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.eco,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Track Your Carbon Footprint',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Log your daily activities to understand and reduce your environmental impact.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build form card with input fields
  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Activity Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Date selection
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMMM d, y').format(_selectedDate)),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            const SizedBox(height: 16),

            // Activity type dropdown
            DropdownButtonFormField<String>(
              value: _selectedType,
              onChanged: _onTypeSelected,
              decoration: const InputDecoration(
                labelText: 'Activity Type',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _availableTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'Please select an activity type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Activity subtype dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubtype,
              onChanged: _selectedType != null ? _onSubtypeSelected : null,
              decoration: const InputDecoration(
                labelText: 'Specific Activity',
                prefixIcon: Icon(Icons.list),
                border: OutlineInputBorder(),
              ),
              items: _availableSubtypes.map((subtype) {
                return DropdownMenuItem<String>(
                  value: subtype,
                  child: Text(subtype),
                );
              }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'Please select a specific activity';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Value input
            TextFormField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Value',
                prefixIcon: const Icon(Icons.straighten),
                border: const OutlineInputBorder(),
                suffixText: _currentFactor?.unit.split('/').last ?? '',
                helperText: _currentFactor != null 
                    ? 'Unit: ${_currentFactor!.unit}'
                    : 'Select activity type first',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                final numValue = double.tryParse(value);
                if (numValue == null || numValue <= 0) {
                  return 'Please enter a valid positive number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build calculation result card
  Widget _buildCalculationCard() {
    return Card(
      color: _calculatedFootprint > 0 
          ? Colors.green[50]
          : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calculate,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Carbon Footprint Calculation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_calculatedFootprint > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_calculatedFootprint.toStringAsFixed(2)} kg CO₂e',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This activity will add to your carbon footprint',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (_currentFactor != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Factor: ${_currentFactor!.factor} ${_currentFactor!.unit}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ] else ...[
              Text(
                'Enter activity details to see carbon footprint calculation',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build save button
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveActivity,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.save),
                SizedBox(width: 8),
                Text(
                  'Save Activity',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
    );
  }
} 