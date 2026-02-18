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

  List<Map<String, dynamic>> allDogs = [];
  List<Map<String, dynamic>> filteredDogs = [];

  bool loading = true;

  String selectedDogType = 'All';
  String searchText = '';

  final List<String> dogTypes = [
    'All',
    'Breeding',
    'Guardian',
    'Pet',
    'Retired',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    loadDogs();
  }

  /// Load all dogs from Supabase
  Future<void> loadDogs() async {
    loading = true;
    setState(() {});

    try {
      final response = await supabase.from('dogs').select().order('dog_name');

      allDogs = List<Map<String, dynamic>>.from(response);

      applyFilters();
    } catch (e) {
      debugPrint('Error loading dogs: $e');
    }

    loading = false;
    setState(() {});
  }

  /// Apply search + dog_type filter
  void applyFilters() {
    filteredDogs = allDogs.where((dog) {
      final dogName = (dog['dog_name'] ?? '').toString().toLowerCase();

      final microchip = (dog['microchip_number'] ?? '')
          .toString()
          .toLowerCase();

      final ala = (dog['dog_ala'] ?? '').toString().toLowerCase();

      final dogType = (dog['dog_type'] ?? '').toString();

      final matchesSearch =
          dogName.contains(searchText) ||
          microchip.contains(searchText) ||
          ala.contains(searchText);

      final matchesType =
          selectedDogType == 'All' || dogType == selectedDogType;

      return matchesSearch && matchesType;
    }).toList();
  }

  void openDogDetails(String dogId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DogDetailsPage(dogId: dogId)),
    ).then((_) {
      loadDogs();
    });
  }

  Widget buildDogTile(Map<String, dynamic> dog) {
    final dogName = dog['dog_name'] ?? '';

    final dogType = dog['dog_type'] ?? '';

    final photoUrl = dog['photo_url'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: ListTile(
        leading: photoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.pets, size: 40),

        title: Text(
          dogName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dogType),

            DogStatusChips(dog: dog),
          ],
        ),

        trailing: const Icon(Icons.chevron_right),

        onTap: () => openDogDetails(dog['id']),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),

      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search name, microchip, ALA',

          prefixIcon: Icon(Icons.search),

          border: OutlineInputBorder(),

          isDense: true,
        ),

        onChanged: (value) {
          searchText = value.toLowerCase();

          applyFilters();

          setState(() {});
        },
      ),
    );
  }

  Widget buildDogTypeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),

      child: DropdownButtonFormField<String>(
        value: selectedDogType,

        decoration: const InputDecoration(
          labelText: 'Dog Type',
          border: OutlineInputBorder(),
        ),

        items: dogTypes.map((type) {
          return DropdownMenuItem(value: type, child: Text(type));
        }).toList(),

        onChanged: (value) {
          selectedDogType = value ?? 'All';

          applyFilters();

          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        buildSearchBar(),

        const SizedBox(height: 8),

        buildDogTypeDropdown(),

        const SizedBox(height: 8),

        Expanded(
          child: RefreshIndicator(
            onRefresh: loadDogs,

            child: ListView.builder(
              itemCount: filteredDogs.length,

              itemBuilder: (context, index) {
                return buildDogTile(filteredDogs[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
