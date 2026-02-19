import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DogNotesTab extends StatefulWidget {
  final String dogId;

  const DogNotesTab({super.key, required this.dogId});

  @override
  State<DogNotesTab> createState() => _DogNotesTabState();
}

class _DogNotesTabState extends State<DogNotesTab> {
  final supabase = Supabase.instance.client;

  List notes = [];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future loadNotes() async {
    final result = await supabase
        .from('dog_notes')
        .select()
        .eq('dog_id', widget.dogId)
        .order('created_at');

    setState(() {
      notes = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,

      itemBuilder: (_, i) {
        final note = notes[i];

        return ListTile(
          title: Text(note['subject'] ?? ''),
          subtitle: Text(note['content'] ?? ''),
        );
      },
    );
  }
}
