import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vehicle_report_page.dart';

class VehicleLogPage extends StatefulWidget {
  const VehicleLogPage({super.key});

  @override
  State<VehicleLogPage> createState() => _VehicleLogPageState();
}

class _VehicleLogPageState extends State<VehicleLogPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> logs = [];

  bool loading = true;

  String selectedVehicle = '';

  bool showBusiness = true;

  final driverController = TextEditingController();
  final notesController = TextEditingController();
  final startKmController = TextEditingController();
  final endKmController = TextEditingController();

  final Map<String, String> vehicleImages = {
    'I30': 'assets/images/I30.png',
    'Staria': 'assets/images/Staria.png',
  };

  final Map<String, bool> vehicleDefaults = {'I30': false, 'Staria': true};

  @override
  void initState() {
    super.initState();
    loadDriverName();
    loadLogs();
  }

  Future<void> loadDriverName() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      driverController.text =
          user.userMetadata?['full_name'] ?? user.email ?? '';
    }
  }

  Future<void> loadLogs() async {
    setState(() => loading = true);

    final response = await supabase
        .from('vehicle_logs')
        .select()
        .order('created_at', ascending: false);

    logs = List<Map<String, dynamic>>.from(response);

    if (logs.isNotEmpty && selectedVehicle.isEmpty) {
      selectedVehicle = logs.first['vehicle_name'];

      showBusiness = vehicleDefaults[selectedVehicle] ?? true;
    }

    carryForwardKm();

    setState(() => loading = false);
  }

  /// AUTO FILL ONLY IF EMPTY (allows manual override)
  void carryForwardKm() {
    if (startKmController.text.isNotEmpty) {
      return;
    }

    final lastTrip = logs.firstWhere(
      (log) => log['vehicle_name'] == selectedVehicle,

      orElse: () => {},
    );

    if (lastTrip.isNotEmpty) {
      startKmController.text = lastTrip['end_km'].toString();
    }
  }

  List<String> get vehicles {
    return logs.map((e) => e['vehicle_name'].toString()).toSet().toList();
  }

  List<Map<String, dynamic>> get filteredLogs {
    return logs.where((log) {
      return log['vehicle_name'] == selectedVehicle &&
          log['is_business'] == showBusiness;
    }).toList();
  }

  void selectVehicle(String vehicle) {
    setState(() {
      selectedVehicle = vehicle;

      showBusiness = vehicleDefaults[vehicle] ?? true;

      /// Clear so carryForwardKm can refill correctly
      startKmController.clear();
    });

    carryForwardKm();
  }

  Future<void> addTrip() async {
    final start = int.tryParse(startKmController.text);

    final end = int.tryParse(endKmController.text);

    if (start == null || end == null) {
      showError("Enter valid KM values");
      return;
    }

    if (end < start) {
      showError("End KM cannot be less than Start KM");

      return;
    }

    final now = DateTime.now();

    final localDate =
        "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";

    final user = supabase.auth.currentUser;

    try {
      await supabase.from('vehicle_logs').insert({
        'vehicle_name': selectedVehicle,
        'driver_name': driverController.text.trim(),
        'notes': notesController.text.trim(),
        'start_km': start,
        'end_km': end,
        'distance_km': end - start,
        'is_business': showBusiness,
        'log_date': localDate,
        'user_id': user?.id,
      });

      notesController.clear();
      endKmController.clear();

      startKmController.clear();

      await loadLogs();

      showMessage("Trip saved");
    } catch (e) {
      showError("Error saving trip: $e");
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String formatDate(String date) {
    final d = DateTime.parse(date);

    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  /// PROFESSIONAL VEHICLE DASHBOARD CARD
  Widget buildVehicleCard(String vehicle) {
    final isSelected = vehicle == selectedVehicle;

    return GestureDetector(
      onTap: () => selectVehicle(vehicle),

      child: Container(
        width: 220,

        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,

            width: isSelected ? 3 : 1,
          ),

          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),

              blurRadius: isSelected ? 12 : 6,

              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),

                child: Image.asset(
                  vehicleImages[vehicle]!,

                  fit: BoxFit.cover,

                  width: double.infinity,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),

              child: Column(
                children: [
                  Text(
                    vehicle,

                    style: const TextStyle(
                      fontSize: 18,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),

                    label: const Text("Report"),

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VehicleReportPage(vehicleName: vehicle),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTripEntry() {
    return Padding(
      padding: const EdgeInsets.all(16),

      child: Column(
        children: [
          TextField(
            controller: driverController,
            decoration: const InputDecoration(labelText: "Driver Name"),
          ),

          TextField(
            controller: notesController,
            decoration: const InputDecoration(labelText: "Notes"),
          ),

          TextField(
            controller: startKmController,

            keyboardType: TextInputType.number,

            decoration: const InputDecoration(
              labelText: "Start KM",

              hintText: "Auto-filled, but can be edited",
            ),
          ),

          TextField(
            controller: endKmController,

            keyboardType: TextInputType.number,

            decoration: const InputDecoration(labelText: "End KM"),
          ),

          const SizedBox(height: 8),

          SwitchListTile(
            title: Text(showBusiness ? "Business" : "Private"),

            subtitle: Text(showBusiness ? "Business trip" : "Private trip"),

            value: showBusiness,

            onChanged: (v) {
              setState(() {
                showBusiness = v;
              });

              startKmController.clear();

              carryForwardKm();
            },
          ),

          ElevatedButton(onPressed: addTrip, child: const Text("Add Trip")),
        ],
      ),
    );
  }

  Widget buildLogList() {
    return Expanded(
      child: ListView.builder(
        itemCount: filteredLogs.length,

        itemBuilder: (_, index) {
          final log = filteredLogs[index];

          return ListTile(
            title: Text(log['notes'] ?? ""),

            subtitle: Text(
              "${log['driver_name']}\n"
              "${formatDate(log['log_date'])}\n"
              "${log['start_km']} → ${log['end_km']}",
            ),

            trailing: Text("${log['distance_km']} km"),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle Log")),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 240,

                  child: ListView(
                    scrollDirection: Axis.horizontal,

                    children: vehicles.map(buildVehicleCard).toList(),
                  ),
                ),

                buildTripEntry(),

                buildLogList(),
              ],
            ),
    );
  }
}
