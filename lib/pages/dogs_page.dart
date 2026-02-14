import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DogsPage extends StatefulWidget {
  const DogsPage({super.key});

  @override
  State<DogsPage> createState() => _DogsPageState();
}

class _DogsPageState extends State<DogsPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _searchController = TextEditingController();

  String _selectedType = 'All';
  List<dynamic> _dogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    setState(() => _loading = true);

    var query = supabase.from('dogs').select();

    final search = _searchController.text.trim();

    // Search across multiple fields
    if (search.isNotEmpty) {
      query = query.or(
        'dog_name.ilike.%$search%,'
        'pet_name.ilike.%$search%,'
        'microchip.ilike.%$search%',
      );
    }

    // Filter by dog_type
    if (_selectedType != 'All') {
      query = query.eq('dog_type', _selectedType);
    }

    final response = await query.order('dog_name', ascending: true);

    setState(() {
      _dogs = response as List<dynamic>;
      _loading = false;
    });
  }

  // ✅ PUT _buildChips HERE (inside class, outside build)
  List<Widget> _buildChips(Map<String, dynamic> dog) {
    List<Widget> chips = [];

    // 🟢 Desexed
    if (dog['desexed'] == true) {
      chips.add(
        const Chip(label: Text('Desexed'), backgroundColor: Colors.green),
      );
    }

    // 🟠 Spay Due
    if (dog['spay_due'] != null) {
      final date = DateTime.parse(dog['spay_due']);
      chips.add(
        Chip(
          label: Text('Spay Due ${date.day}/${date.month}/${date.year}'),
          backgroundColor: Colors.orange.shade200,
        ),
      );
    }

    // 🔵 Dog Status
    if (dog['dog_status'] != null) {
      chips.add(
        Chip(
          label: Text(dog['dog_status']),
          backgroundColor: Colors.blue.shade200,
        ),
      );
    }

    // 🟣 Sale Status
    if (dog['sale_status'] != null) {
      chips.add(
        Chip(
          label: Text(dog['sale_status']),
          backgroundColor: Colors.purple.shade200,
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dogs')),
      body: Column(
        children: [
          // 🔍 Search Field
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search dog...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _loadDogs(),
            ),
          ),

          // 🐶 Dog Type Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Dog Type'),
              items:
                  const [
                        'All',
                        'Breeding',
                        'Pet',
                        'Guardian',
                        'Retired',
                        'Unknown',
                      ]
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
              onChanged: (val) {
                setState(() {
                  _selectedType = val!;
                });
                _loadDogs();
              },
            ),
          ),

          const SizedBox(height: 10),

          // 📋 Dog List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _dogs.isEmpty
                ? const Center(child: Text('No dogs found'))
                : ListView.builder(
                    itemCount: _dogs.length,
                    itemBuilder: (context, index) {
                      final dog = _dogs[index] as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🖼 Thumbnail
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: dog['dog_photo'] != null
                                    ? NetworkImage(dog['dog_photo'])
                                    : null,
                                child: dog['dog_photo'] == null
                                    ? const Icon(Icons.pets)
                                    : null,
                              ),

                              const SizedBox(width: 12),

                              // 📋 Dog Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dog['dog_name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text('Pet: ${dog['pet_name'] ?? ''}'),
                                    Text(
                                      'Microchip: ${dog['microchip'] ?? ''}',
                                    ),
                                    Text('ALA: ${dog['dog_ala'] ?? ''}'),

                                    const SizedBox(height: 8),

                                    // 🏷 Chips Row
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: -8,
                                      children: _buildChips(dog),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
