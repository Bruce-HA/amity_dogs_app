import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'vehicle_log_page.dart';
import 'dogs_page.dart';

class DashboardPage extends StatefulWidget {
  DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final supabase = Supabase.instance.client;

  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = supabase.auth.currentUser;

    final profile = await supabase
        .from('profiles')
        .select('name')
        .eq('user_id', user!.id)
        .single();

    setState(() {
      _userName = profile['name'];
    });
  }

  String greeting() {
    if (_userName == null) return "";

    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good morning, ${_userName!.split(' ').first}";
    }

    if (hour < 17) {
      return "Good afternoon, ${_userName!.split(' ').first}";
    }

    return "Good evening, ${_userName!.split(' ').first}";
  }

  Widget tile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(16),

      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal.shade100,

          borderRadius: BorderRadius.circular(16),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(icon, size: 40),

            const SizedBox(height: 10),

            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Amity Labradoodles"),

            Text(greeting(), style: const TextStyle(fontSize: 12)),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),

            onPressed: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.count(
          crossAxisCount: 2,

          crossAxisSpacing: 16,

          mainAxisSpacing: 16,

          children: [
            tile(Icons.pets, "Dogs", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DogsPage()),
              );
            }),

            tile(Icons.directions_car, "Vehicle Log", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleLogPage()),
              );
            }),
          ],
        ),
      ),
    );
  }
}
