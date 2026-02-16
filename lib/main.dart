import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'pages/dashboard_page.dart';

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
      title: 'Amity Labradoodles',

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),

      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,

        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;

          if (session == null) {
            return LoginPage();
          } else {
            return DashboardPage();
          }
        },
      ),
    );
  }
}
