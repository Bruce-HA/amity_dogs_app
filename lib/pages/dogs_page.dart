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

  String selectedFilter = 'All';
  String searchText = '';

  final filters = [
    'All',
    'Breeding',
    'Guardian',
    'Pet',
    'Retired',
    'Spay Scheduled',
    'Spay Due Soon',
    'Spay Overdue',
  ];

  @override
  void initState() {
    super.initState();
    loadDogs();
  }

  Future<void> loadDogs() async {
    loading = true;
    setState(() {});

    final response = await supabase
        .from('dogs')
        .select()
        .order('dob', ascending: false);

    allDogs = List<Map<String, dynamic>>.from(response);

    applyFilters();

    loading = false;
    setState(() {});
  }

  void applyFilters() {
    filteredDogs = allDogs.where((dog) {
      final name = (dog['dog_name'] ?? '').toString().toLowerCase();

      final phone = (dog['phone_1st'] ?? '').toLowerCase();

      final microchip = (dog['microchip'] ?? '').toString().toLowerCase();

      final ala = (dog['dog_ala'] ?? '').toString().toLowerCase();

      final matchesSearch =
          name.contains(searchText) ||
          phone.contains(searchText) ||
          microchip.contains(searchText) ||
          ala.contains(searchText);

      bool matchesFilter = true;

      if (selectedFilter == 'Spay Scheduled') {
        matchesFilter = dog['spay_due'] != null;
      } else if (selectedFilter == 'Spay Due Soon') {
        final dueStr = dog['spay_due'];

        if (dueStr == null) {
          matchesFilter = false;
        } else {
          final due = DateTime.parse(dueStr);

          final days = due.difference(DateTime.now()).inDays;

          matchesFilter = days >= 0 && days <= 30;
        }
      } else if (selectedFilter == 'Spay Overdue') {
        final dueStr = dog['spay_due'];

        if (dueStr == null) {
          matchesFilter = false;
        } else {
          final due = DateTime.parse(dueStr);

          final days = due.difference(DateTime.now()).inDays;

          matchesFilter = days < 0;
        }
      } else if (selectedFilter != 'All') {
        matchesFilter = dog['dog_type'] == selectedFilter;
      }

      return matchesSearch && matchesFilter;
    }).toList();

    // Sort by spay_due ascending (closest first)
    filteredDogs.sort((a, b) {
      final aDue = a['spay_due'];
      final bDue = b['spay_due'];

      if (aDue == null && bDue == null) return 0;

      if (aDue == null) return 1;

      if (bDue == null) return -1;

      final aDate = DateTime.parse(aDue);

      final bDate = DateTime.parse(bDue);

      return aDate.compareTo(bDate);
    });
  }

  String calculateAge(String? dobStr) {
    if (dobStr == null) return '';

    final dob = DateTime.parse(dobStr);

    final now = DateTime.now();

    int years = now.year - dob.year;

    int months = now.month - dob.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    return '$years y $months m';
  }

  Color getAgeColor(String? dobStr) {
    if (dobStr == null) return Colors.black;

    final dob = DateTime.parse(dobStr);
    final now = DateTime.now();

    final totalMonths = (now.year - dob.year) * 12 + (now.month - dob.month);

    final years = totalMonths / 12.0;

    if (years < 1) {
      return Colors.orange;
    }

    if (years < 5) {
      return Colors.green;
    }

    return Colors.red;
  }

  void openDog(String id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DogDetailsPage(dogId: id)),
    );
  }

  Widget buildDogTile(Map<String, dynamic> dog) {
    final age = calculateAge(dog['dob']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: ListTile(
        leading: const Icon(Icons.pets, size: 40),

        title: Text(
          dog['dog_name'] ?? '',

          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ALA: ${dog['dog_ala'] ?? ''}'),

            Text(dog['dog_type'] ?? ''),

            Text('Microchip: ${dog['microchip'] ?? ''}'),

            Text('Sex: ${dog['sex'] ?? ''}'),

            Text(
              'Age: $age',
              style: TextStyle(
                color: getAgeColor(dog['dob']),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            DogStatusChips(dog: dog),
          ],
        ),

        trailing: const Icon(Icons.chevron_right),

        onTap: () => openDog(dog['id']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search Name, ALA, Microchip',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),

            onChanged: (value) {
              searchText = value.toLowerCase();

              applyFilters();

              setState(() {});
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),

          child: DropdownButtonFormField(
            value: selectedFilter,

            items: filters
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),

            onChanged: (value) {
              selectedFilter = value!;

              applyFilters();

              setState(() {});
            },
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: filteredDogs.length,

            itemBuilder: (_, i) => buildDogTile(filteredDogs[i]),
          ),
        ),
      ],
    );
  }
}
