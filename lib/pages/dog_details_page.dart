import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tabs/dog_photos_tab.dart';

class DogDetailsPage extends StatefulWidget {
  final String dogId;

  const DogDetailsPage({super.key, required this.dogId});

  @override
  State<DogDetailsPage> createState() => _DogDetailsPageState();
}

class _DogDetailsPageState extends State<DogDetailsPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? dog;
  Map<String, dynamic>? mother;
  Map<String, dynamic>? father;

  bool loading = true;

  late TabController tabController;

  final String baseUrl =
      "https://phkwizyrpfzoecugpshb.supabase.co/storage/v1/object/public/dog_files";

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 1, vsync: this);

    loadDog();
  }

  Future<void> loadDog() async {
    loading = true;
    setState(() {});

    final response =
        await supabase.from('dogs').select().eq('id', widget.dogId).single();

    dog = response;

    await loadParents();

    loading = false;
    setState(() {});
  }

  Future<void> loadParents() async {
    if (dog == null) return;

    final motherAla = dog!['mother_ala'];
    final fatherAla = dog!['father_ala'];

    if (motherAla != null) {
      final m = await supabase
          .from('dogs')
          .select()
          .eq('dog_ala', motherAla)
          .maybeSingle();

      mother = m;
    }

    if (fatherAla != null) {
      final f = await supabase
          .from('dogs')
          .select()
          .eq('dog_ala', fatherAla)
          .maybeSingle();

      father = f;
    }
  }

  String heroUrl(Map<String, dynamic> d) {
    return "$baseUrl/${d['id']}/${d['dog_ala']}/photo/hero.jpg";
  }

  Widget heroImage(Map<String, dynamic> d, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        heroUrl(d),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            "assets/images/no_photo.png",
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  Widget buildParentCard(String label, Map<String, dynamic>? parent) {
    if (parent == null) {
      return Card(
        child: ListTile(
          title: Text(label),
          subtitle: const Text("Unknown"),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: heroImage(parent, 64),

        title: Text(parent['dog_name'] ?? ''),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(parent['dog_ala'] ?? ''),
            Text(parent['dog_type'] ?? ''),
          ],
        ),

        trailing: const Icon(Icons.chevron_right),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DogDetailsPage(dogId: parent['id']),
            ),
          );
        },
      ),
    );
  }

  Widget buildDetails() {
    if (dog == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text("ALA: ${dog!['dog_ala'] ?? ''}"),

            Text("Microchip: ${dog!['microchip'] ?? ''}"),

            Text("Colour: ${dog!['colour'] ?? ''}"),

            Text("Dog Type: ${dog!['dog_type'] ?? ''}"),

            const SizedBox(height: 8),

            Text(
              "Owner: ${dog!['owner_person_id'] ?? 'Not assigned'}",
            ),

            const SizedBox(height: 8),

            Text("Notes: ${dog!['notes'] ?? ''}"),
          ],
        ),
      ),
    );
  }

  Widget buildHero() {
    if (dog == null) return const SizedBox();

    return Column(
      children: [
        heroImage(dog!, 200),

        const SizedBox(height: 8),

        Text(
          dog!['dog_name'] ?? '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),

        Text(dog!['dog_ala'] ?? ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dog?['dog_name'] ?? ''),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildHero(),

            buildDetails(),

            buildParentCard("Mother", mother),

            buildParentCard("Father", father),

            const SizedBox(height: 16),

            SizedBox(
              height: 600,
              child: DogPhotosTab(
                dogId: dog!['id'],
                dogAla: dog!['dog_ala'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}