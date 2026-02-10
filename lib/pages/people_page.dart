import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: FutureBuilder(
        future: supabase.from('people').select().order('last_name'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data as List<dynamic>;

          if (rows.isEmpty) {
            return const Center(child: Text('No people found'));
          }

          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final person = rows[index] as Map<String, dynamic>;
              return ListTile(
                title: Text(
                  '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}',
                ),
                subtitle: Text(
                  (person['roles'] as List<dynamic>?)?.join(', ') ?? '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
