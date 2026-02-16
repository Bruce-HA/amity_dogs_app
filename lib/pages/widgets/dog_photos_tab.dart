import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DogPhotosTab extends StatefulWidget {
  final String dogId;

  const DogPhotosTab({super.key, required this.dogId});

  @override
  State<DogPhotosTab> createState() => _DogPhotosTabState();
}

class _DogPhotosTabState extends State<DogPhotosTab> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> photos = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await supabase
          .from('dog_photos')
          .select()
          .eq('dog_id', widget.dogId)
          .order('created_at', ascending: false);

      photos = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading photos: $e');
    }

    setState(() {
      loading = false;
    });
  }

  void openPhoto(String url, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: Column(
            children: [
              Expanded(child: Center(child: Image.network(url))),

              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPhotoCard(Map<String, dynamic> photo) {
    final url = photo['url'] ?? '';

    final description = photo['description'] ?? '';

    return GestureDetector(
      onTap: () => openPhoto(url, description),

      child: Card(
        clipBehavior: Clip.antiAlias,

        child: Column(
          children: [
            Expanded(
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (photos.isEmpty) {
      return const Center(child: Text('No photos yet'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,

        crossAxisSpacing: 8,

        mainAxisSpacing: 8,

        childAspectRatio: 1,
      ),

      itemCount: photos.length,

      itemBuilder: (context, index) {
        return buildPhotoCard(photos[index]);
      },
    );
  }
}
