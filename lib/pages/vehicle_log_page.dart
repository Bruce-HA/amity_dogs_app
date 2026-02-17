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

  final _formKey = GlobalKey<FormState>();

  final _startKmController = TextEditingController();
  final _endKmController = TextEditingController();
  final _notesController = TextEditingController();

  String? _driverName;

  bool _loading = true;
  bool _saving = false;

  String _selectedVehicle = "I30";

  bool _isBusiness = false;

  int _i30Km = 0;
  int _stariaKm = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadDriver();

    await _loadTotals();

    await _selectVehicle("I30");

    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadDriver() async {
    final user = supabase.auth.currentUser;

    final profile = await supabase
        .from('profiles')
        .select('name')
        .eq('user_id', user!.id)
        .single();

    _driverName = profile['name'];
  }

  Future<void> _loadTotals() async {
    final i30 = await supabase
        .from('vehicle_logs')
        .select('end_km')
        .eq('vehicle_name', 'I30')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final staria = await supabase
        .from('vehicle_logs')
        .select('end_km')
        .eq('vehicle_name', 'Staria')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    _i30Km = i30?['end_km'] ?? 0;
    _stariaKm = staria?['end_km'] ?? 0;
  }

  Future<void> _selectVehicle(String vehicle) async {
    final last = await supabase
        .from('vehicle_logs')
        .select('end_km')
        .eq('vehicle_name', vehicle)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    setState(() {
      _selectedVehicle = vehicle;

      // default trip type per vehicle
      _isBusiness = vehicle == "Staria";

      _startKmController.text = last?['end_km']?.toString() ?? "0";
    });
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    final startKm = int.parse(_startKmController.text);
    final endKm = int.parse(_endKmController.text);

    if (endKm < startKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("End KM cannot be less than Start KM"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() => _saving = true);

    try {
      final user = supabase.auth.currentUser;

      await supabase.from('vehicle_logs').insert({
        'user_id': user!.id,

        'driver_name': _driverName,

        'vehicle_name': _selectedVehicle,

        'is_business': _isBusiness,

        'start_km': startKm,

        'end_km': endKm,

        'notes': _notesController.text,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => _saving = false);
  }

  Widget vehicleCard(String name, String image, int km) {
    final selected = _selectedVehicle == name;

    return Expanded(
      child: Card(
        color: selected ? Colors.teal.shade100 : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _selectVehicle(name),
                child: Image.asset(image, height: 80),
              ),

              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),

              Text("$km km"),

              const SizedBox(height: 6),

              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 18),

                label: const Text("Report"),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleReportPage(vehicleName: name),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _report() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Report generator next step")));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Log"),

        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _report,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              Row(
                children: [
                  vehicleCard("I30", "assets/images/i30.png", _i30Km),

                  vehicleCard("Staria", "assets/images/staria.png", _stariaKm),
                ],
              ),

              const SizedBox(height: 10),

              // BUSINESS / PRIVATE SWITCH AT TOP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const Text("Private"),

                  Switch(
                    value: _isBusiness,

                    onChanged: (value) {
                      setState(() {
                        _isBusiness = value;
                      });
                    },
                  ),

                  const Text("Business"),
                ],
              ),

              const SizedBox(height: 10),

              TextFormField(
                initialValue: _driverName,

                readOnly: true,

                decoration: const InputDecoration(labelText: "Driver"),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _startKmController,

                keyboardType: TextInputType.number,

                decoration: const InputDecoration(labelText: "Start KM"),

                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _endKmController,

                keyboardType: TextInputType.number,

                decoration: const InputDecoration(labelText: "End KM"),

                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,

                decoration: const InputDecoration(labelText: "Notes"),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: _saving ? null : _saveLog,

                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text("Save Log"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
