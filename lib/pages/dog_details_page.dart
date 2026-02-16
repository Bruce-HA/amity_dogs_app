import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/dog_files_section.dart';

class DogDetailsPage extends StatefulWidget {
  final String dogId;

  const DogDetailsPage({super.key, required this.dogId});

  @override
  State<DogDetailsPage> createState() => _DogDetailsPageState();
}

class _DogDetailsPageState extends State<DogDetailsPage> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? dog;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDog();
  }

  Future<void> loadDog() async {
    final result = await supabase
        .from('dogs')
        .select()
        .eq('id', widget.dogId)
        .single();

    setState(() {
      dog = result;
      loading = false;
    });
  }

  String calculateAge(DateTime dob) {
    final now = DateTime.now();

    int years = now.year - dob.year;

    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }

    return "$years years";
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final photo = dog!['dog_photo'];

    final dob = dog!['dob'] != null ? DateTime.parse(dog!['dob']) : null;

    return Scaffold(
      appBar: AppBar(title: Text(dog!['dog_name'] ?? "")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Center(
              child: CircleAvatar(
                radius: 60,

                backgroundImage: (photo != null && photo.toString().isNotEmpty)
                    ? NetworkImage(photo)
                    : const AssetImage('assets/images/no_photo.png')
                          as ImageProvider,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              dog!['dog_name'] ?? "",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            Text("Pet Name: ${dog!['pet_name'] ?? ""}"),

            Text("ALA: ${dog!['dog_ala'] ?? ""}"),

            Text("Microchip: ${dog!['microchip'] ?? ""}"),

            const SizedBox(height: 16),

            Text("Sex: ${dog!['sex'] ?? ""}"),

            Text("Colour: ${dog!['colour'] ?? ""}"),

            if (dob != null)
              Text("DOB: ${DateFormat('dd MMM yyyy').format(dob)}"),

            if (dob != null) Text("Age: ${calculateAge(dob)}"),

            Text("Dog Type: ${dog!['dog_type'] ?? ""}"),

            Text("Status: ${dog!['dog_status'] ?? ""}"),

            const SizedBox(height: 16),

            Text("Desexed: ${dog!['desexed'] == true ? "Yes" : "No"}"),

            if (dog!['spay_due'] != null)
              Text(
                "Spay Due: ${DateFormat('dd MMM yyyy').format(DateTime.parse(dog!['spay_due']))}",
              ),

            const SizedBox(height: 16),

            if (dog!['notes'] != null) Text("Notes: ${dog!['notes']}"),

            DogFilesSection(dogId: widget.dogId),
          ],
        ),
      ),
    );
  }
}
