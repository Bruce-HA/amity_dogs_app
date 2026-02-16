import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/dog_photos_tab.dart';
import 'widgets/dog_files_tab.dart';
import 'widgets/dog_notes_tab.dart';

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

  bool loading = true;

  bool isLocked = true;

  bool isAdmin = false;

  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);

    loadDog();

    checkAdmin();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> checkAdmin() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    /// For now, any logged in user is admin
    /// Later we connect to profiles.role

    isAdmin = true;
  }

  Future<void> loadDog() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await supabase
          .from('dogs')
          .select()
          .eq('id', widget.dogId)
          .single();

      dog = response;

      isLocked = dog?['locked'] ?? true;
    } catch (e) {
      debugPrint('Error loading dog: $e');
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> toggleLock() async {
    if (!isAdmin) return;

    final newState = !isLocked;

    await supabase
        .from('dogs')
        .update({'locked': newState})
        .eq('id', widget.dogId);

    setState(() {
      isLocked = newState;
    });
  }

  void openLinkedDog(String? dogId) {
    if (dogId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DogDetailsPage(dogId: dogId)),
    );
  }

  Widget buildHeader() {
    final name = dog?['name'] ?? '';

    final imageUrl = dog?['photo_url'];

    return Column(
      children: [
        /// IMAGE
        Container(
          width: 150,
          height: 150,

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),

          clipBehavior: Clip.antiAlias,

          child: imageUrl != null
              ? Image.network(imageUrl, fit: BoxFit.cover)
              : const Icon(Icons.pets, size: 60, color: Colors.grey),
        ),

        const SizedBox(height: 12),

        /// NAME + LOCK
        Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(width: 8),

            IconButton(
              icon: Icon(isLocked ? Icons.lock : Icons.lock_open),

              color: isLocked ? Colors.red : Colors.green,

              onPressed: toggleLock,
            ),
          ],
        ),
      ],
    );
  }

  Widget buildInfoTile({
    required String label,

    required String? value,

    String? linkedDogId,
  }) {
    return ListTile(
      title: Text(label),

      subtitle: Text(value ?? '', style: const TextStyle(fontSize: 16)),

      trailing: linkedDogId != null ? const Icon(Icons.chevron_right) : null,

      onTap: linkedDogId != null ? () => openLinkedDog(linkedDogId) : null,
    );
  }

  Widget buildPedigree() {
    return Column(
      children: [
        buildInfoTile(
          label: 'Mother',
          value: dog?['mother_name'],
          linkedDogId: dog?['mother_id'],
        ),

        buildInfoTile(
          label: 'Father',
          value: dog?['father_name'],
          linkedDogId: dog?['father_id'],
        ),

        buildInfoTile(label: 'Owner', value: dog?['owner_name']),
      ],
    );
  }

  Widget buildTabs() {
    return Expanded(
      child: Column(
        children: [
          TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: 'Photos'),

              Tab(text: 'Files'),

              Tab(text: 'Notes'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: tabController,

              children: [
                DogPhotosTab(dogId: widget.dogId),

                DogFilesTab(dogId: widget.dogId),

                DogNotesTab(dogId: widget.dogId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dog Details')),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dog == null
          ? const Center(child: Text('Dog not found'))
          : Column(
              children: [
                const SizedBox(height: 12),

                buildHeader(),

                const SizedBox(height: 8),

                buildPedigree(),

                buildTabs(),
              ],
            ),
    );
  }
}
