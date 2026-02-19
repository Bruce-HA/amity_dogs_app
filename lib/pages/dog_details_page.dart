import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../tabs/dog_photos_tab.dart';
import '../tabs/dog_files_tab.dart';
import '../tabs/dog_notes_tab.dart';
import '../tabs/dog_correspondence_tab.dart';

import '../services/dog_lock_service.dart';
import '../pages/cards/spay_status_card.dart';

import 'people_detail_page.dart';
import 'dog_details_page.dart';

class DogDetailsPage extends StatefulWidget {
  final dynamic dogId;

  const DogDetailsPage({super.key, required this.dogId});

  @override
  State<DogDetailsPage> createState() => _DogDetailsPageState();
}

class _DogDetailsPageState extends State<DogDetailsPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? dog;
  Map<String, dynamic>? mother;
  Map<String, dynamic>? father;
  Map<String, dynamic>? owner;

  String? heroImageUrl;

  bool loading = true;
  bool wasUnlockedByUser = false;

  @override
  void initState() {
    super.initState();
    loadDog();
  }

  @override
  void dispose() {
    if (wasUnlockedByUser && dog != null) {
      DogLockService.toggleLock(dogId: dog!['id'], locked: false);
    }

    super.dispose();
  }

  Future loadDog() async {
    try {
      final dogResult = await supabase
          .from('dogs')
          .select()
          .eq('id', widget.dogId.toString())
          .maybeSingle();

      if (dogResult == null) {
        throw Exception("Dog not found");
      }

      final photoResult = await supabase
          .from('dog_photos')
          .select('url')
          .eq('dog_id', widget.dogId)
          .limit(1);

      Map<String, dynamic>? motherResult;
      Map<String, dynamic>? fatherResult;
      Map<String, dynamic>? ownerResult;

      if (dogResult['mother_id'] != null) {
        motherResult = await supabase
            .from('dogs')
            .select()
            .eq('id', dogResult['mother_id'])
            .maybeSingle();
      }

      if (dogResult['father_id'] != null) {
        fatherResult = await supabase
            .from('dogs')
            .select()
            .eq('id', dogResult['father_id'])
            .maybeSingle();
      }

      if (dogResult['people_id'] != null) {
        ownerResult = await supabase
            .from('people')
            .select()
            .eq('people_id', dogResult['people_id'])
            .maybeSingle();
      }

      if (!mounted) return;

      setState(() {
        dog = dogResult;
        mother = motherResult;
        father = fatherResult;
        owner = ownerResult;

        if (photoResult.isNotEmpty) {
          heroImageUrl = photoResult.first['url'];
        }

        loading = false;
      });
    } catch (e) {
      debugPrint("DogDetailsPage load error:");
      debugPrint(e.toString());

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  String calculateAge(DateTime dob) {
    final now = DateTime.now();

    int years = now.year - dob.year;
    int months = now.month - dob.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    return "$years yr $months m";
  }

  Future call(String phone) async {
    await launchUrl(Uri.parse("tel:$phone"));
  }

  Future email(String emailAddress) async {
    await launchUrl(Uri.parse("mailto:$emailAddress"));
  }

  Widget parentCard(String title, Map<String, dynamic>? parent) {
    if (parent == null) {
      return Card(
        child: ListTile(
          title: Text(title),
          subtitle: const Text("Not recorded"),
        ),
      );
    }

    return Card(
      child: ListTile(
        leading: FutureBuilder(
          future: supabase
              .from('dog_photos')
              .select('url')
              .eq('dog_id', parent['id'])
              .limit(1),

          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Icon(Icons.pets);
            }

            return CircleAvatar(
              backgroundImage: NetworkImage(snapshot.data!.first['url']),
            );
          },
        ),

        title: Text(parent['name'] ?? ''),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parent['ala_number'] != null)
              Text("ALA: ${parent['ala_number'] ?? ''}"),

            Text(parent['dog_type'] ?? ''),
          ],
        ),

        trailing: const Icon(Icons.arrow_forward),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DogDetailsPage(dogId: parent['id'].toString()),
            ),
          );
        },
      ),
    );
  }

  void showSecondContactPopup() {
    showDialog(
      context: context,

      builder: (_) => AlertDialog(
        title: const Text("Second Contact"),

        content: Column(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              "${owner!['first_name_2nd']} ${owner!['last_name_2nd']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            Text(owner!['relationship_2nd'] ?? ''),

            Row(
              children: [
                if (owner!['phone_2nd'] != null)
                  IconButton(
                    icon: const Icon(Icons.phone),
                    onPressed: () => call(owner!['phone_2nd']),
                  ),

                if (owner!['email_2nd'] != null)
                  IconButton(
                    icon: const Icon(Icons.email),
                    onPressed: () => email(owner!['email_2nd']),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget ownerCard() {
    if (owner == null) return const SizedBox();

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PeopleDetailPage(peopleId: owner!['people_id']),
            ),
          );
        },

        child: Padding(
          padding: const EdgeInsets.all(12),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                "${owner?['first_name_1st'] ?? ''} ${owner?['last_name_1st'] ?? ''}",

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Row(
                children: [
                  if (owner!['phone_1st'] != null)
                    IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () => call(owner!['phone_1st']),
                    ),

                  if (owner!['email_1st'] != null)
                    IconButton(
                      icon: const Icon(Icons.email),
                      onPressed: () => email(owner!['email_1st']),
                    ),

                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      DefaultTabController.of(context)?.animateTo(3);
                    },
                  ),
                ],
              ),

              if (owner!['first_name_2nd'] != null)
                ActionChip(
                  label: const Text("2nd Contact"),
                  onPressed: showSecondContactPopup,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dob = DateTime.tryParse(dog?['date_of_birth'] ?? '');

    final age = dob != null ? calculateAge(dob) : '';

    final ageYears = dob != null ? DateTime.now().year - dob.year : 0;

    return DefaultTabController(
      length: 4,

      child: Scaffold(
        appBar: AppBar(
          title: Text(dog?['name'] ?? 'Dog Details'),
          actions: [
            IconButton(
              icon: Icon(dog!['locked'] ? Icons.lock : Icons.lock_open),

              onPressed: () async {
                await DogLockService.toggleLock(
                  dogId: dog!['id'],
                  locked: dog!['locked'],
                );

                if (dog!['locked']) wasUnlockedByUser = true;

                loadDog();
              },
            ),

            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: dog!['locked'] ? null : () {},
            ),
          ],
        ),

        body: Column(
          children: [
            if (heroImageUrl != null)
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(heroImageUrl!, fit: BoxFit.cover),
              ),

            Padding(
              padding: const EdgeInsets.all(12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(dog!['dog_type']),

                  Text(
                    age,
                    style: TextStyle(
                      color: ageYears > 5 ? Colors.red : Colors.black,
                    ),
                  ),

                  parentCard("Mother", mother),

                  parentCard("Father", father),

                  ownerCard(),

                  if (dog != null)
                    SpayStatusCard(dog: dog!, onUpdated: loadDog),
                ],
              ),
            ),

            const TabBar(
              tabs: [
                Tab(text: "Photos"),
                Tab(text: "Files"),
                Tab(text: "Notes"),
                Tab(text: "Correspondence"),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  DogPhotosTab(dogId: dog?['id']?.toString() ?? ''),

                  DogFilesTab(dogId: dog!['id']),

                  DogNotesTab(dogId: dog!['id']),

                  DogCorrespondenceTab(dogId: dog!['id']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
