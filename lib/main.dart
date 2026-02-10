import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'pages/vehicle_log_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://phkwizyrpfzoecugpshb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBoa3dpenlycGZ6b2VjdWdwc2hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkzNjYyODIsImV4cCI6MjA4NDk0MjI4Mn0.ScSHlVVB83GFDCsUXTyjj_3r2Bde2gvFLE5zEJKbRJ8',
  );

  runApp(const AmityDogsApp());
}

class AmityDogsApp extends StatelessWidget {
  const AmityDogsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amity Dogs',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const VehicleLogPage(),
    );
  }
}
