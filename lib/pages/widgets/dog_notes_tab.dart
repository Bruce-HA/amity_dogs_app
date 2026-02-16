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

  List<Map<String, dynamic>> notes = [];

  bool loading = true;

  final subjectController = TextEditingController();

  final contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await supabase
          .from('dog_notes')
          .select()
          .eq('dog_id', widget.dogId)
          .order('created_at', ascending: false);

      notes = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> addNote() async {
    final subject = subjectController.text.trim();

    final content = contentController.text.trim();

    if (subject.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter subject and note')));

      return;
    }

    final user = supabase.auth.currentUser;

    final email = user?.email ?? 'Unknown';

    try {
      await supabase.from('dog_notes').insert({
        'dog_id': widget.dogId,

        'subject': subject,

        'content': content,

        'created_by': email,
      });

      subjectController.clear();
      contentController.clear();

      Navigator.pop(context);

      loadNotes();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void showAddDialog() {
    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          title: const Text('Add Note'),

          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: 'Note'),
                  maxLines: 4,
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            ElevatedButton(onPressed: addNote, child: const Text('Save')),
          ],
        );
      },
    );
  }

  Widget buildNoteCard(Map<String, dynamic> note) {
    final subject = note['subject'] ?? '';

    final content = note['content'] ?? '';

    final createdBy = note['created_by'] ?? '';

    final createdAt = note['created_at'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

      child: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// SUBJECT
            Text(
              subject,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            /// CONTENT
            Text(content),

            const SizedBox(height: 8),

            /// FOOTER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  createdBy,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                Text(
                  createdAt.toString().substring(0, 16),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
          ? const Center(child: Text('No notes yet'))
          : RefreshIndicator(
              onRefresh: loadNotes,

              child: ListView.builder(
                itemCount: notes.length,

                itemBuilder: (context, index) {
                  return buildNoteCard(notes[index]);
                },
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,

        child: const Icon(Icons.add),
      ),
    );
  }
}
