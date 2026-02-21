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

  final String baseUrl =
      "https://phkwizyrpfzoecugpshb.supabase.co/storage/v1/object/public/dog_files";

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  /*
  =====================================================
  LOAD PHOTOS
  =====================================================
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

    loading = false;
    setState(() {});
  }

  /*
  =====================================================
  BUILD STORAGE URL
  =====================================================
  */

  String getFullUrl(String fileName) {
    fileName = fileName.split("/").last;

    return "$baseUrl/${widget.dogId}/${widget.dogAla}/photo/$fileName";
  }

  /*
  =====================================================
  UPLOAD PHOTO
  =====================================================
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

    final storagePath =
        "${widget.dogId}/${widget.dogAla}/photo/$fileName";

    await supabase.storage
        .from('dog_files')
        .upload(
          storagePath,
          File(file.path),
          fileOptions: const FileOptions(upsert: true),
        );

    await supabase.from('dog_photos').insert({
      'dog_id': widget.dogId,
      'url': fileName,
      'description': '',
    });

    await loadPhotos();
  }

  /*
  =====================================================
  PHOTO CARD
  =====================================================
  */

  Widget buildPhotoCard(Map<String, dynamic> photo) {
    final fileName = photo['url'] ?? "";

    final fullUrl = getFullUrl(fileName);

    final description = photo['description'] ?? "";

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoViewerPage(
              imageUrl: fullUrl,
              photo: photo,
              dogId: widget.dogId,
              dogAla: widget.dogAla,
            ),
          ),
        );

        if (result == true) {
          await loadPhotos();
          widget.onHeroChanged?.call();
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                fullUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            if (description.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(6),
                color: Colors.grey[100],
                child: Text(
                  description,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /*
  =====================================================
  UI
  =====================================================
  */

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.all(8),
          child: ElevatedButton.icon(
            onPressed: uploadPhoto,
            icon: const Icon(
                Icons.add_a_photo),
            label:
                const Text("Upload Photo"),
          ),
        ),
        Expanded(
          child: photos.isEmpty
              ? const Center(
                  child: Text(
                      "No photos uploaded"))
              : GridView.builder(
                  padding:
                      const EdgeInsets.all(8),
                  itemCount:
                      photos.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing:
                        8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder:
                      (context, index) {
                    return buildPhotoCard(
                        photos[index]);
                  },
                ),
        ),
      ],
    );
  }
}