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

  List photos = [];

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  Future loadPhotos() async {
    final result = await supabase
        .from('dog_photos')
        .select()
        .eq('dog_id', widget.dogId)
        .order('created_at');

    setState(() {
      photos = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: photos.length,

      itemBuilder: (context, index) {
        final photo = photos[index];

        return ListTile(
          leading: Image.network(
            photo['url'],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),

          title: Text(photo['description'] ?? ''),

          onTap: () {
            showDialog(
              context: context,

              builder: (_) => Dialog(child: Image.network(photo['url'])),
            );
          },
        );
      },
    );
  }
}
