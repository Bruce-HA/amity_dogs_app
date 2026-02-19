import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DogFilesTab extends StatefulWidget {
  final String dogId;

  const DogFilesTab({super.key, required this.dogId});

  @override
  State<DogFilesTab> createState() => _DogFilesTabState();
}

class _DogFilesTabState extends State<DogFilesTab> {
  final supabase = Supabase.instance.client;

  List files = [];

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future loadFiles() async {
    final result = await supabase
        .from('dog_files')
        .select()
        .eq('dog_id', widget.dogId)
        .order('created_at');

    setState(() {
      files = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: files.length,

      itemBuilder: (_, i) {
        final file = files[i];

        return ListTile(
          title: Text(file['file_name'] ?? ''),

          subtitle: Text(file['description'] ?? ''),
        );
      },
    );
  }
}
