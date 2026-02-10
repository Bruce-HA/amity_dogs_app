import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleLogPage extends StatefulWidget {
  const VehicleLogPage({super.key});

  @override
  State<VehicleLogPage> createState() => _VehicleLogPageState();
}

class _VehicleLogPageState extends State<VehicleLogPage> {
  DateTime _selectedMonth = DateTime.now();
  late Future<List<dynamic>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  DateTime get _startOfSelectedMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);

  DateTime get _startOfNextMonth =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
      _refresh();
    });
  }

  void _refresh() {
    _logsFuture = Supabase.instance.client
        .from('vehicle_logs')
        .select()
        .gte('log_date', _startOfSelectedMonth.toIso8601String())
        .lt('log_date', _startOfNextMonth.toIso8601String())
        .order('log_date', ascending: false);

    setState(() {});
  }

  Future<Map<String, int>> _fetchMonthlyTotals() async {
    final data = await Supabase.instance.client
        .from('vehicle_logs')
        .select('distance_km, is_business')
        .gte('log_date', _startOfSelectedMonth.toIso8601String())
        .lt('log_date', _startOfNextMonth.toIso8601String());

    int businessKm = 0;
    int privateKm = 0;

    for (final row in data) {
      final km = row['distance_km'] ?? 0;
      if (row['is_business'] == true) {
        businessKm += km as int;
      } else {
        privateKm += km as int;
      }
    }

    return {'business': businessKm, 'private': privateKm};
  }

  Future<List<Map<String, dynamic>>> _fetchVehicleMonthlyTotals() async {
    final data = await Supabase.instance.client
        .from('vehicle_logs')
        .select('vehicle_name, distance_km, is_business')
        .gte('log_date', _startOfSelectedMonth.toIso8601String())
        .lt('log_date', _startOfNextMonth.toIso8601String());

    final Map<String, Map<String, int>> totals = {};

    for (final row in data) {
      final vehicle = row['vehicle_name'] as String;
      final km = (row['distance_km'] ?? 0) as int;
      final isBusiness = row['is_business'] == true;

      totals.putIfAbsent(vehicle, () => {'business': 0, 'private': 0});

      if (isBusiness) {
        totals[vehicle]!['business'] = totals[vehicle]!['business']! + km;
      } else {
        totals[vehicle]!['private'] = totals[vehicle]!['private']! + km;
      }
    }

    return totals.entries
        .map(
          (e) => {
            'vehicle': e.key,
            'business': e.value['business'],
            'private': e.value['private'],
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Log')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final added = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const _AddVehicleLogSheet(),
          );

          if (added == true) {
            _refresh();
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          FutureBuilder<Map<String, int>>(
            future: _fetchMonthlyTotals(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }

              final totals = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Business KM',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${totals['business']}'),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Private KM',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${totals['private']}'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          // inserted here
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchVehicleMonthlyTotals(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows.map((row) {
                    return Card(
                      child: ListTile(
                        title: Text(row['vehicle']),
                        subtitle: Text(
                          'Business: ${row['business']} km  •  '
                          'Private: ${row['private']} km',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // to here
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _logsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }

                final logs = snapshot.data!;
                if (logs.isEmpty) {
                  return const Center(child: Text('No vehicle logs yet'));
                }

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      title: Text(log['vehicle_name']),
                      subtitle: Text(
                        'Start ${log['start_km'] ?? '-'} → End ${log['end_km']} '
                        '(${log['distance_km'] ?? 0} km)',
                      ),
                      trailing: Chip(
                        label: Text(
                          log['is_business'] ? 'Business' : 'Private',
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
    );
  }
}

/* ---------------- ADD LOG SHEET ---------------- */

class _AddVehicleLogSheet extends StatefulWidget {
  const _AddVehicleLogSheet();

  @override
  State<_AddVehicleLogSheet> createState() => _AddVehicleLogSheetState();
}

class _AddVehicleLogSheetState extends State<_AddVehicleLogSheet> {
  final _startKmController = TextEditingController();
  final _endKmController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newVehicleController = TextEditingController();

  List<String> _vehicles = [];
  String? _selectedVehicle;
  bool _isAddingNewVehicle = false;
  bool _isBusiness = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    final data = await Supabase.instance.client
        .from('vehicle_logs')
        .select('vehicle_name');

    setState(() {
      _vehicles = data
          .map<String>((e) => e['vehicle_name'] as String)
          .toSet()
          .toList();
    });
  }

  Future<void> _populateStartKm(String vehicle) async {
    final data = await Supabase.instance.client
        .from('vehicle_logs')
        .select('end_km')
        .eq('vehicle_name', vehicle)
        .not('end_km', 'is', null)
        .order('end_km', ascending: false)
        .limit(1);

    if (data.isNotEmpty) {
      _startKmController.text = data.first['end_km'].toString();
    }
  }

  // insert new code below
  bool get _canSave {
    if (_isAddingNewVehicle) {
      return _newVehicleController.text.trim().isNotEmpty;
    }
    return _selectedVehicle != null;
  }

  //insert new code above
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Vehicle Log',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButtonFormField<String>(
              hint: const Text('Select vehicle'),
              items: [
                ..._vehicles.map(
                  (v) => DropdownMenuItem(value: v, child: Text(v)),
                ),
                const DropdownMenuItem(
                  value: '__new__',
                  child: Text('Add new vehicle…'),
                ),
              ],
              onChanged: (value) async {
                if (value == '__new__') {
                  setState(() => _isAddingNewVehicle = true);
                } else {
                  setState(() {
                    _isAddingNewVehicle = false;
                    _selectedVehicle = value;
                  });
                  await _populateStartKm(value!);
                }
              },
            ),
            if (_isAddingNewVehicle)
              TextField(
                controller: _newVehicleController,
                decoration: const InputDecoration(
                  labelText: 'New vehicle name',
                ),
              ),
            TextField(
              controller: _startKmController,
              decoration: const InputDecoration(labelText: 'Start KM'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _endKmController,
              decoration: const InputDecoration(labelText: 'End KM'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            SwitchListTile(
              title: Text(_isBusiness ? 'Business use' : 'Private use'),
              value: _isBusiness,
              onChanged: (v) => setState(() => _isBusiness = v),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                // below here
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_saving || !_canSave)
                        ? null
                        : () async {
                            setState(() => _saving = true);

                            final vehicleName = _isAddingNewVehicle
                                ? _newVehicleController.text.trim()
                                : _selectedVehicle;

                            try {
                              print('Attempting to save vehicle log...');

                              await Supabase.instance.client
                                  .from('vehicle_logs')
                                  .insert({
                                    'vehicle_name': vehicleName,
                                    'start_km': int.tryParse(
                                      _startKmController.text,
                                    ),
                                    'end_km': int.tryParse(
                                      _endKmController.text,
                                    ),
                                    'description': _descriptionController.text,
                                    'log_date': DateTime.now()
                                        .toIso8601String(),
                                    'is_business': _isBusiness,
                                  });

                              print('Vehicle log saved successfully');

                              if (context.mounted) {
                                Navigator.pop(context, true);
                              }
                            } catch (e) {
                              print('ERROR saving vehicle log: $e');

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _saving = false);
                              }
                            }
                          },
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Save'),
                  ),
                ),
                // above here
              ],
            ),
          ],
        ),
      ),
    );
  }
}
