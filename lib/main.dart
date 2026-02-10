import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'pages/vehicle_log_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
