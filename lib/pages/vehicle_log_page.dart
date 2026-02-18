import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vehicle_reports_page.dart';

class VehicleLogPage extends StatefulWidget {
  const VehicleLogPage({super.key});

  @override
  State<VehicleLogPage> createState() => _VehicleLogPageState();
}

class _VehicleLogPageState extends State<VehicleLogPage> {
  final supabase = Supabase.instance.client;

  /// Vehicle list (must match Supabase vehicle_name exactly)
  final List<String> vehicles = ['I30', 'Staria'];

  /// Stores last KM per vehicle
  final Map<String, int> lastKm = {};

  String selectedVehicle = 'I30';

  final endKmController = TextEditingController();
  final notesController = TextEditingController();

  bool isBusiness = true;
  bool loading = true;
  bool saving = false;

  final String driverName = 'Bruce McLean';

  @override
  void initState() {
    super.initState();
    loadAllVehicleKms();
  }

  /// Load latest KM per vehicle from Supabase
  Future<void> loadAllVehicleKms() async {
    try {
      final response = await supabase
          .from('vehicle_logs')
          .select('vehicle_name, end_km, created_at')
          .order('created_at', ascending: false);

      for (var row in response) {
        final vehicle = row['vehicle_name'];
        final km = row['end_km'];

        if (!lastKm.containsKey(vehicle)) {
          lastKm[vehicle] = km;
        }
      }
    } catch (e) {
      debugPrint("Error loading vehicle KMs: $e");
    }

    setState(() {
      loading = false;
    });
  }

  /// Save new log entry
  Future<void> saveLog() async {
    final endKm = int.tryParse(endKmController.text);

    if (endKm == null) return;

    saving = true;
    setState(() {});

    try {
      await supabase.from('vehicle_logs').insert({
        'vehicle_name': selectedVehicle,
        'start_km': lastKm[selectedVehicle] ?? 0,
        'end_km': endKm,
        'trip_type': isBusiness ? 'Business' : 'Private',
        'notes': notesController.text,
        'driver_name': driverName,
      });

      /// Update local value immediately
      lastKm[selectedVehicle] = endKm;

      endKmController.clear();
      notesController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vehicle log saved')));
    } catch (e) {
      debugPrint("Save error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving log')));
    }

    saving = false;
    setState(() {});
  }

  /// Vehicle tile widget
  Widget vehicleTile(String vehicle) {
    final isSelected = vehicle == selectedVehicle;
    final km = lastKm[vehicle] ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedVehicle = vehicle;
        });
      },

      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade200 : Colors.grey.shade200,

          borderRadius: BorderRadius.circular(16),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Image.asset('assets/images/$vehicle.png', height: 70),

            const SizedBox(height: 8),

            Text(
              vehicle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            Text('$km km', style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VehicleReportsPage(vehicleName: vehicle),
                  ),
                );
              },

              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Report"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Log')),

      /// Safe overflow-proof layout
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              /// Vehicle tiles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: vehicles.map(vehicleTile).toList(),
              ),

              const SizedBox(height: 20),

              /// Trip type toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Private'),

                  Switch(
                    value: isBusiness,
                    onChanged: (value) {
                      setState(() {
                        isBusiness = value;
                      });
                    },
                  ),

                  const Text('Business'),
                ],
              ),

              const SizedBox(height: 20),

              /// Driver
              Text(
                'Driver\n$driverName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// Start KM display
              Text(
                'Start KM\n${lastKm[selectedVehicle] ?? 0}',
                style: const TextStyle(fontSize: 20),
              ),

              const SizedBox(height: 20),

              /// End KM input
              TextField(
                controller: endKmController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'End KM'),
              ),

              const SizedBox(height: 20),

              /// Notes input
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),

              const SizedBox(height: 30),

              /// Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : saveLog,

                  child: saving
                      ? const CircularProgressIndicator()
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
