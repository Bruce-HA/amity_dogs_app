import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

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

  // just add below
  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 9,
        ),
      ),
    );
  }

  // just added above
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

  Future<List<Map<String, dynamic>>> _fetchMonthlyLogsForPdf() async {
    final data = await Supabase.instance.client
        .from('vehicle_logs')
        .select()
        .gte('log_date', _startOfSelectedMonth.toIso8601String())
        .lt('log_date', _startOfNextMonth.toIso8601String())
        .order('log_date', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _fetchVehicleMonthlyTotals() async {
    final data = await Supabase.instance.client
        .from('vehicle_logs')
        .select('vehicle_name, distance_km, is_business')
        .gte('log_date', _startOfSelectedMonth.toIso8601String())
        .lt('log_date', _startOfNextMonth.toIso8601String());

    final Map<String, Map<String, int>> vehicleTotals = {};

    for (final row in data) {
      final vehicle = row['vehicle_name'];
      final km = row['distance_km'] ?? 0;
      final isBusiness = row['is_business'] == true;

      vehicleTotals.putIfAbsent(vehicle, () => {'business': 0, 'private': 0});

      if (isBusiness) {
        vehicleTotals[vehicle]!['business'] =
            vehicleTotals[vehicle]!['business']! + (km as int);
      } else {
        vehicleTotals[vehicle]!['private'] =
            vehicleTotals[vehicle]!['private']! + (km as int);
      }
    }

    return vehicleTotals.entries
        .map(
          (e) => {
            'vehicle': e.key,
            'business': e.value['business'],
            'private': e.value['private'],
          },
        )
        .toList();
  }

  Future<String?> _selectVehicleForPdf() async {
    final data = await Supabase.instance.client
        .from('vehicle_logs')
        .select('vehicle_name')
        .gte('log_date', _startOfSelectedMonth.toIso8601String())
        .lt('log_date', _startOfNextMonth.toIso8601String());

    final vehicles = data
        .map<String>((e) => e['vehicle_name'] as String)
        .toSet()
        .toList();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Vehicle'),
          content: SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('All Vehicles'),
                  onTap: () => Navigator.pop(context, null),
                ),
                ...vehicles.map(
                  (v) => ListTile(
                    title: Text(v),
                    onTap: () => Navigator.pop(context, v),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // delete code below here
  Future<void> _exportMonthlyPdf() async {
    print('PDF EXPORT STARTED');

    final selectedVehicle = await _selectVehicleForPdf();

    final ttf = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final font = pw.Font.ttf(ttf);

    final pdf = pw.Document(theme: pw.ThemeData.withFont(base: font));

    final totals = await _fetchMonthlyTotals();
    var query = Supabase.instance.client
        .from('vehicle_logs')
        .select() // MUST come first in your version
        .gte('log_date', _startOfSelectedMonth.toIso8601String())
        .lt('log_date', _startOfNextMonth.toIso8601String());

    if (selectedVehicle != null) {
      query = query.eq('vehicle_name', selectedVehicle);
    }

    final logs = await query.order('log_date');

    final logoBytes = await rootBundle.load('assets/images/amity_logo.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    pdf.addPage(
      pw.MultiPage(
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Vehicle Log Report',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 6),

          pw.Text('Month: ${DateFormat('MMMM yyyy').format(_selectedMonth)}'),

          pw.SizedBox(height: 16),

          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(65), // Date
              1: const pw.FixedColumnWidth(90), // Driver
              2: const pw.FixedColumnWidth(70), // Vehicle
              3: const pw.FixedColumnWidth(50), // Start
              4: const pw.FixedColumnWidth(50), // End
              5: const pw.FixedColumnWidth(55), // KM
              6: const pw.FixedColumnWidth(55), // Use
            },
            children: [
              /// HEADER ROW
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _pdfCell('Date', bold: true),
                  _pdfCell('Driver', bold: true),
                  _pdfCell('Vehicle', bold: true),
                  _pdfCell('Start', bold: true),
                  _pdfCell('End', bold: true),
                  _pdfCell('KM', bold: true),
                  _pdfCell('Use', bold: true),
                ],
              ),

              /// DATA ROWS
              ...logs.map((log) {
                final tripDate =
                    DateTime.tryParse(log['log_date'] ?? '') ?? DateTime.now();

                return pw.TableRow(
                  children: [
                    _pdfCell(DateFormat('dd/MM/yyyy').format(tripDate)),
                    _pdfCell(log['driver_name'] ?? 'Unknown'),
                    _pdfCell(log['vehicle_name']),
                    _pdfCell(log['start_km'].toString()),
                    _pdfCell(log['end_km'].toString()),
                    _pdfCell(log['distance_km'].toString()),
                    _pdfCell(log['is_business'] ? 'Business' : 'Private'),
                  ],
                );
              }).toList(),
            ],
          ),

          pw.SizedBox(height: 20),

          pw.Divider(),

          pw.SizedBox(height: 10),

          pw.Text(
            'Monthly Totals',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 6),

          pw.Text('Business KM: ${totals['business']}'),
          pw.Text('Private KM: ${totals['private']}'),

          pw.SizedBox(height: 30),

          pw.Divider(),

          pw.SizedBox(height: 20),

          pw.Text('Driver Signature: ________________________________'),

          pw.SizedBox(height: 8),

          pw.Text('Date: ____________________'),
        ],
      ),
    );

    final bytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/Vehicle_Log_${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}.pdf',
    );

    await file.writeAsBytes(bytes);

    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Vehicle Log')),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/amity_logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('Vehicle Log'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportMonthlyPdf,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),

                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // end of insert
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
                    // insert below here
                    return ListTile(
                      title: Text(log['vehicle_name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Driver: ${log['driver_name'] ?? 'Unknown'}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Start ${log['start_km']} → End ${log['end_km']} '
                            '  •  Distance: ${log['distance_km']} km',
                          ),
                          if ((log['description'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                log['description'],
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),

                      trailing: Chip(
                        label: Text(
                          log['is_business'] ? 'Business' : 'Private',
                        ),
                      ),
                    );
                    // Replace above here
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

  Future<void> _saveLog() async {
    setState(() => _saving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;

      final startKm = int.tryParse(_startKmController.text.trim()) ?? 0;
      final endKm = int.tryParse(_endKmController.text.trim()) ?? 0;

      if (endKm <= startKm) {
        throw Exception('End KM must be greater than Start KM');
      }

      final distance = endKm - startKm;

      final vehicleName = _isAddingNewVehicle
          ? _newVehicleController.text.trim()
          : _selectedVehicle;

      if (vehicleName == null || vehicleName.isEmpty) {
        throw Exception('Please select or enter a vehicle');
      }

      final driverName =
          user?.userMetadata?['full_name'] ?? user?.email ?? 'Unknown';

      print('Current user: $user');

      await Supabase.instance.client.from('vehicle_logs').insert({
        'vehicle_name': vehicleName,
        'start_km': startKm,
        'end_km': endKm,
        'distance_km': distance,
        'description': _descriptionController.text.trim(),
        'log_date': DateTime.now().toIso8601String(),
        'is_business': _isBusiness,
        'driver_id': user?.id,
        'driver_name': driverName,
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
              value: _isBusiness,
              onChanged: (v) => setState(() => _isBusiness = v),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveLog,
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
