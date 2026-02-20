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

  final String baseUrl =
      "https://phkwizyrpfzoecugpshb.supabase.co/storage/v1/object/public/dog_files";

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future loadPhotos() async {
    loading = true;
    setState(() {});

    final result = await supabase
        .from('dog_photos')
        .select()
        .eq('dog_id', widget.dogId)
        .order('created_at');

    photos = List<Map<String, dynamic>>.from(result);

    loading = false;
    setState(() {});
  }

  /// Build full Supabase Storage URL
  String getFullUrl(String fileName) {
    return "$baseUrl/${widget.dogId}/photo/$fileName";
  }

  void openViewer(String fullUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            fullUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Icon(Icons.broken_image, size: 80),
                ),
          ),
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
      return const Center(child: Text("No photos found"));
    }

    return ListView.builder(
      itemCount: photos.length,

      itemBuilder: (context, index) {

        final photo = photos[index];

        final fileName = photo['url'] ?? "";

        final fullUrl = getFullUrl(fileName);

        return ListTile(

          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              fullUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported),
            ),
          ),

          title: Text(photo['description'] ?? ""),

          subtitle: Text(fileName),

          onTap: () => openViewer(fullUrl),
        );
      },
    );
  }
}
