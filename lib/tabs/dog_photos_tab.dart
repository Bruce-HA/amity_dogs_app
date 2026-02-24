import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'photo_viewer_page.dart';

class DogPhotosTab extends StatefulWidget {
  final String dogId;
  final String dogAla;
  final VoidCallback? onHeroChanged;

  const DogPhotosTab({
    super.key,
    required this.dogId,
    required this.dogAla,
    this.onHeroChanged,
  });

  @override
  State<DogPhotosTab> createState() => _DogPhotosTabState();
}

class _DogPhotosTabState extends State<DogPhotosTab> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> photos = [];

  bool loading = true;

  String? heroFileName;

  final String baseUrl =
      "https://phkwizyrpfzoecugpshb.supabase.co/storage/v1/object/public/dog_files";

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  /*
  LOAD PHOTOS
  */

  Future<void> loadPhotos() async {
    loading = true;
    setState(() {});

    final response = await supabase
        .from('dog_photos')
        .select()
        .eq('dog_id', widget.dogId)
        .order('created_at', ascending: false);

    photos = List<Map<String, dynamic>>.from(response);

    await detectHero();

    loading = false;
    setState(() {});
  }

  /*
  DETECT HERO FILE
  */

  Future<void> detectHero() async {

    heroFileName = null;

    try {

      final heroBytes = await supabase.storage
          .from('dog_files')
          .download(
        "${widget.dogId}/${widget.dogAla}/photo/hero.jpg?v=${DateTime.now().millisecondsSinceEpoch}",
      );

      for (final photo in photos) {

        final fileName = photo['url'];

        final bytes = await supabase.storage
            .from('dog_files')
            .download(
          "${widget.dogId}/${widget.dogAla}/photo/$fileName",
        );

        if (bytes.length == heroBytes.length) {

          heroFileName = fileName;

          break;
        }
      }

    } catch (_) {}

  }

  /*
  BUILD URL
  */

  String getFullUrl(String fileName) {
    return "$baseUrl/${widget.dogId}/${widget.dogAla}/photo/$fileName";
  }

  /*
  UPLOAD PHOTO
  */

  Future<void> uploadPhoto() async {
    final picker = ImagePicker();

    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (file == null) return;

    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}.jpg";

    final path =
        "${widget.dogId}/${widget.dogAla}/photo/$fileName";

    await supabase.storage
        .from('dog_files')
        .upload(path, File(file.path),
            fileOptions: const FileOptions(upsert: true));

    await supabase.from('dog_photos').insert({
      'dog_id': widget.dogId,
      'url': fileName,
      'description': '',
    });

    await loadPhotos();
  }

  /*
  PHOTO CARD
  */

  Widget buildPhotoCard(Map<String, dynamic> photo) {
    final fileName = photo['url'];

    final url = getFullUrl(fileName);

    final description = photo['description'] ?? "";

    final isHero = fileName == heroFileName;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoViewerPage(
              imageUrl: url,
              photo: photo,
              dogId: widget.dogId,
              dogAla: widget.dogAla,
            ),
          ),
        );

        if (result == true) {

          // Force fresh hero detection
          heroFileName = null;

          await loadPhotos();

          // notify parent
          widget.onHeroChanged?.call();

          // force UI refresh
          if (mounted) {
            setState(() {});
          }
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isHero)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding:
                            const EdgeInsets.all(4),
                        decoration:
                            const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (description.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.all(6),
                width: double.infinity,
                color: Colors.grey[200],
                child: Text(
                  description,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /*
  UI
  */

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator());
    }

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: uploadPhoto,
          icon: const Icon(Icons.add_a_photo),
          label: const Text("Upload Photo"),
        ),
        Expanded(
          child: GridView.builder(
            padding:
                const EdgeInsets.all(8),
            itemCount: photos.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) =>
                buildPhotoCard(photos[index]),
          ),
        ),
      ],
    );
  }
}