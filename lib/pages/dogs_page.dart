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

    try {
      final response = await supabase.from('dogs').select().order('dog_name');

      dogs = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading dogs: $e');
    }

    setState(() {
      loading = false;
    });
  }

  List<Map<String, dynamic>> get filteredDogs {
    if (searchText.isEmpty) return dogs;

    return dogs.where((dog) {
      final name = (dog['dog_name'] ?? '').toString().toLowerCase();

      return name.contains(searchText.toLowerCase());
    }).toList();
  }

  void openDog(Map<String, dynamic> dog) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DogDetailsPage(dogId: dog['id'])),
    ).then((_) {
      loadDogs();
    });
  }

  Widget buildDogTile(Map<String, dynamic> dog) {
    final name = dog['dog_name'] ?? '';

    final breed = dog['breed'] ?? '';

    final imageUrl = dog['photo_url'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: InkWell(
        onTap: () => openDog(dog),

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),

                clipBehavior: Clip.antiAlias,

                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.pets, size: 30, color: Colors.grey),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (breed.isNotEmpty)
                      Text(breed, style: TextStyle(color: Colors.grey[600])),

                    DogStatusChips(dog: dog),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dogs')),

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
