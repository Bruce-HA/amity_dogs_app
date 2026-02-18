import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dog_details_page.dart';
import 'widgets/dog_status_chips.dart';

class DogsPage extends StatefulWidget {
  const DogsPage({super.key});

  @override
  State<DogsPage> createState() => _DogsPageState();
}

class _DogsPageState extends State<DogsPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> dogs = [];

  bool loading = true;

  String searchText = '';

  @override
  void initState() {
    super.initState();
    loadDogs();
  }

  Future<void> loadDogs() async {
    setState(() {
      loading = true;
    });

    final response = await supabase.from('dogs').select().order('dog_name');

    dogs = List<Map<String, dynamic>>.from(response);

    setState(() {
      loading = false;
    });
  }

  List<Map<String, dynamic>> get filteredDogs {
    if (searchText.isEmpty) return dogs;

    return dogs.where((dog) {
      final name = dog['dog_name']?.toString().toLowerCase() ?? '';

      final chip = dog['microchip_number']?.toString().toLowerCase() ?? '';

      return name.contains(searchText.toLowerCase()) ||
          chip.contains(searchText.toLowerCase());
    }).toList();
  }

  void openDog(Map<String, dynamic> dog) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DogDetailsPage(dogId: dog['id'])),
    );
  }

  Widget buildDogTile(Map<String, dynamic> dog) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: ListTile(
        title: Text(
          dog['dog_name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: DogStatusChips(dog: dog),

        trailing: const Icon(Icons.chevron_right),

        onTap: () => openDog(dog),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),

            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search dogs',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),

              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredDogs.length,

                    itemBuilder: (context, index) {
                      return buildDogTile(filteredDogs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
