import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DogsPage extends StatelessWidget {
  const DogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(title: const Text('Dogs')),
      body: FutureBuilder(
        future: supabase.from('dogs').select().order('dog_name'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rows = snapshot.data as List<dynamic>;

          if (rows.isEmpty) {
            return const Center(child: Text('No dogs found'));
          }

          return ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final dog = rows[index] as Map<String, dynamic>;
              return ListTile(
                title: Text(dog['dog_name'] ?? ''),
                subtitle: Text(dog['pet_name'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
