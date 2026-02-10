import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleLogPage extends StatefulWidget {
  const VehicleLogPage({super.key});

  @override
  State<VehicleLogPage> createState() => _VehicleLogPageState();
}

class _VehicleLogPageState extends State<VehicleLogPage> {
  late Future<List<dynamic>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _logsFuture = Supabase.instance.client
        .from('vehicle_logs')
        .select()
        .order('log_date', ascending: false);
    setState(() {});
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
      body: FutureBuilder<List<dynamic>>(
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
                  label: Text(log['is_business'] ? 'Business' : 'Private'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

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
        .select('vehicle_name')
        .order('vehicle_name');

    final names = data
        .map<String>((e) => e['vehicle_name'] as String)
        .toSet()
        .toList();

    setState(() {
      _vehicles = names;
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

    if (data.isNotEmpty && data.first['end_km'] != null) {
      _startKmController.text = data.first['end_km'].toString();
    } else {
      _startKmController.clear();
    }
  }

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
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedVehicle,
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
                  setState(() {
                    _isAddingNewVehicle = true;
                    _selectedVehicle = null;
                    _startKmController.clear();
                  });
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
              subtitle: Text(
                _isBusiness
                    ? 'This trip will count toward business kilometres'
                    : 'This trip will be recorded as private use',
              ),
              value: _isBusiness,
              onChanged: (v) => setState(() => _isBusiness = v),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            setState(() => _saving = true);

                            final vehicleName = _isAddingNewVehicle
                                ? _newVehicleController.text
                                : _selectedVehicle;

                            await Supabase.instance.client
                                .from('vehicle_logs')
                                .insert({
                                  'vehicle_name': vehicleName,
                                  'start_km': int.tryParse(
                                    _startKmController.text.trim(),
                                  ),
                                  'end_km': int.tryParse(
                                    _endKmController.text.trim(),
                                  ),
                                  'description': _descriptionController.text,
                                  'log_date': DateTime.now().toIso8601String(),
                                  'is_business': _isBusiness,
                                });

                            if (context.mounted) {
                              Navigator.pop(context, true);
                            }
                          },
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
