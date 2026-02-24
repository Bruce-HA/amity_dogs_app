import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';


class PhotoViewerPage extends StatefulWidget {
  final String imageUrl;
  final Map<String, dynamic> photo;
  final String dogId;
  final String dogAla;

  const PhotoViewerPage({
    super.key,
    required this.imageUrl,
    required this.photo,
    required this.dogId,
    required this.dogAla,
  });

  @override
  State<PhotoViewerPage> createState() =>
      _PhotoViewerPageState();
}

class _PhotoViewerPageState
    extends State<PhotoViewerPage> {
  final supabase = Supabase.instance.client;

  /*
  SET HERO
  */

  Future<void> setHeroImage() async {
    final fileName = widget.photo['url'];

    final source =
        "${widget.dogId}/${widget.dogAla}/photo/$fileName";

    final hero =
        "${widget.dogId}/${widget.dogAla}/photo/hero.jpg";

    final bytes =
        await supabase.storage.from('dog_files').download(source);

    await supabase.storage.from('dog_files').uploadBinary(
          hero,
          bytes,
          fileOptions:
              const FileOptions(upsert: true),
        );

    Navigator.pop(context, true);
  }

  /*
  DELETE
  */

  Future<void> deletePhoto() async {
    final fileName = widget.photo['url'];

    await supabase.storage.from('dog_files').remove([
      "${widget.dogId}/${widget.dogAla}/photo/$fileName"
    ]);

    await supabase
        .from('dog_photos')
        .delete()
        .eq('id', widget.photo['id']);

    Navigator.pop(context, true);
  }

  /*
  SAVE
  */

  Future<void> saveToDevice() async {
    final response =
        await http.get(Uri.parse(widget.imageUrl));

    await ImageGallerySaver.saveImage(
        response.bodyBytes);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(
      content: Text("Saved to device"),
    ));
  }

  /*
  SHARE
  */

  Future<void> sharePhoto() async {
    final response =
        await http.get(Uri.parse(widget.imageUrl));

    final dir =
        await getTemporaryDirectory();

    final file =
        File("${dir.path}/photo.jpg");

    await file.writeAsBytes(
        response.bodyBytes);

    await Share.shareXFiles(
        [XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF111111),
        iconTheme:
            const IconThemeData(
                color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.star,
                color: Colors.amber),
            onPressed:
                setHeroImage,
          ),
          IconButton(
            icon: const Icon(
                Icons.download,
                color: Colors.white),
            onPressed:
                saveToDevice,
          ),
          IconButton(
            icon: const Icon(
                Icons.share,
                color: Colors.white),
            onPressed:
                sharePhoto,
          ),
          IconButton(
            icon: const Icon(
                Icons.delete,
                color: Colors.red),
            onPressed:
                deletePhoto,
          ),
        ],
      ),
      body: Center(
        child:
            InteractiveViewer(
          child: Image.network(
              widget.imageUrl),
        ),
      ),
    );
  }
}