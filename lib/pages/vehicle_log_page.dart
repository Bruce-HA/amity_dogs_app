import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/vehicle_log_pdf.dart';

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

  final descriptionController = TextEditingController();
  final startKmController = TextEditingController();
  final endKmController = TextEditingController();
  final notesController = TextEditingController();

  /// Vehicle images (must match database names exactly)
  final Map<String, String> vehicleImages = {

    'I30': 'assets/images/I30.png',

    'Staria': 'assets/images/Staria.png',

  };

  /// Default vehicle mode
  final Map<String, bool> vehicleDefaults = {

    'I30': false,

    'Staria': true,

  };

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> loadLogs() async {

    setState(() => loading = true);

    try {

      final response =
          await supabase
              .from('vehicle_logs')
              .select()
              .order('created_at', ascending: false);

      logs =
          List<Map<String, dynamic>>
              .from(response);

      if (logs.isNotEmpty &&
          selectedVehicle.isEmpty) {

        selectedVehicle =
            logs.first['vehicle_name'];

        showBusiness =
            vehicleDefaults[selectedVehicle] ?? true;

        carryForwardKm();
      }

    } catch (e) {

      debugPrint('Load error: $e');

    }

    setState(() => loading = false);
  }

  List<String> get vehicles {

    return logs
        .map((e) =>
            e['vehicle_name']
                .toString())
        .toSet()
        .toList();
  }

  List<Map<String, dynamic>>
      get filteredLogs {

    return logs.where((log) {

      return log['vehicle_name'] ==
                 selectedVehicle &&
             log['is_business'] ==
                 showBusiness;

    }).toList();
  }

  /// Carry forward odometer using last vehicle trip
  void carryForwardKm() {

    final lastTrip =
        logs.firstWhere(

      (log) =>
          log['vehicle_name'] ==
              selectedVehicle,

      orElse: () => {},

    );

    if (lastTrip.isNotEmpty) {

      startKmController.text =
          lastTrip['end_km']
              .toString();

    } else {

      startKmController.clear();
    }
  }

  void selectVehicle(String vehicle) {

    setState(() {

      selectedVehicle = vehicle;

      showBusiness =
          vehicleDefaults[vehicle] ?? true;

    });

    carryForwardKm();
  }

  Future<void> addTrip() async {

    final start =
        int.tryParse(
            startKmController.text);

    final end =
        int.tryParse(
            endKmController.text);

    if (start == null ||
        end == null) return;

    try {

      await supabase
          .from('vehicle_logs')
          .insert({

        'vehicle_name':
            selectedVehicle,

        'log_date':
            DateTime.now()
                .toIso8601String(),

        'created_at':
            DateTime.now()
                .toIso8601String(),

        'description':
            descriptionController.text,

        'start_km': start,

        'end_km': end,

        'distance_km':
            end - start,

        'is_business':
            showBusiness,

        'driver_name':
            supabase.auth
                    .currentUser
                    ?.email ??
                '',

        'notes':
            notesController.text,

      });

      descriptionController.clear();
      endKmController.clear();
      notesController.clear();

      await loadLogs();

    } catch (e) {

      debugPrint(
          'Insert error: $e');
    }
  }

  Future<void> generateVehicleReports(
      String vehicle) async {

    final vehicleLogs =
        logs.where(
          (log) =>
              log['vehicle_name'] ==
              vehicle,
        ).toList();

    if (vehicleLogs.isEmpty)
      return;

    final businessLogs =
        vehicleLogs.where(
      (log) =>
          log['is_business'] ==
          true,
    ).toList();

    final privateLogs =
        vehicleLogs.where(
      (log) =>
          log['is_business'] ==
          false,
    ).toList();

    final firstDate =
        vehicleLogs.last['log_date']
            .toString()
            .substring(0, 10);

    final lastDate =
        vehicleLogs.first['log_date']
            .toString()
            .substring(0, 10);

    await savePdf(
        vehicle,
        'AllTrips',
        vehicleLogs,
        firstDate,
        lastDate);

    await savePdf(
        vehicle,
        'Business',
        businessLogs,
        firstDate,
        lastDate);

    await savePdf(
        vehicle,
        'Private',
        privateLogs,
        firstDate,
        lastDate);

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(
            'Reports saved for $vehicle'),
      ),
    );
  }

  Future<void> savePdf(
    String vehicle,
    String type,
    List<Map<String, dynamic>> reportLogs,
    String firstDate,
    String lastDate,
  ) async {

    if (reportLogs.isEmpty)
      return;

    final pdf =
        await VehicleLogPdfService
            .generate(
      logs: reportLogs,
      landscape: true,
    );

    final Uint8List bytes =
        await pdf.save();

    final fileName =
        'Amity_${vehicle}_${type}_${firstDate}_to_${lastDate}.pdf';

    final storagePath =
        '$vehicle/$fileName';

    await supabase.storage
        .from('vehicle_reports')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions:
              const FileOptions(
                  upsert: true),
        );
  }

  Widget buildVehicleCard(
      String vehicle) {

    final selected =
        vehicle ==
            selectedVehicle;

    return GestureDetector(

      onTap: () =>
          selectVehicle(vehicle),

      child: Card(

        color: selected
            ? Colors.blue
            : null,

        child: SizedBox(

          width: 180,

          child: Column(

            children: [

              Expanded(

                child: Image.asset(
                  vehicleImages[
                      vehicle]!,
                  fit: BoxFit.cover,
                ),
              ),

              Padding(

                padding:
                    const EdgeInsets
                        .all(8),

                child: Text(
                  vehicle,
                  style:
                      TextStyle(
                    color: selected
                        ? Colors.white
                        : null,
                    fontSize: 18,
                  ),
                ),
              ),

              IconButton(

                icon: const Icon(
                    Icons.picture_as_pdf),

                onPressed: () =>
                    generateVehicleReports(
                        vehicle),

              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget buildTripEntry() {

    return Padding(

      padding:
          const EdgeInsets.all(12),

      child: Column(

        children: [

          Row(

            children: [

              const Text(
                  'Business'),

              Switch(
                value:
                    showBusiness,
                onChanged:
                    (v) {

                  setState(() {
                    showBusiness =
                        v;
                  });
                },
              ),

              const Text(
                  'Private'),

            ],
          ),

          TextField(
            controller:
                descriptionController,
            decoration:
                const InputDecoration(
              labelText:
                  'Description',
            ),
          ),

          TextField(
            controller:
                startKmController,
            decoration:
                const InputDecoration(
              labelText:
                  'Start KM',
            ),
          ),

          TextField(
            controller:
                endKmController,
            decoration:
                const InputDecoration(
              labelText:
                  'End KM',
            ),
          ),

          ElevatedButton(
            onPressed:
                addTrip,
            child:
                const Text(
                    'Add Trip'),
          ),

        ],
      ),
    );
  }

  Widget buildLogList() {

    return Expanded(

      child: ListView.builder(

        itemCount:
            filteredLogs.length,

        itemBuilder:
            (_, index) {

          final log =
              filteredLogs[index];

          final distance =
              log['distance_km'] ??
              (log['end_km'] -
                  log['start_km']);

          return ListTile(

            title: Text(
                log['description'] ??
                    ''),

            subtitle: Text(
              '${log['log_date'].toString().substring(0, 16)}\n'
              '${log['start_km']} → ${log['end_km']}',
            ),

            trailing: Text(
                '$distance km'),

          );
        },
      ),
    );
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
            'Vehicle Log'),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Column(

              children: [

                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection:
                        Axis.horizontal,
                    children: vehicles
                        .map(
                            buildVehicleCard)
                        .toList(),
                  ),
                ),

                buildTripEntry(),

                buildLogList(),
