
// FULL PRODUCTION DogDetailsPage
// Bottom-sheet searchable selectors
// Inline editing
// Confirm save / cancel
// Hero image editing
// Lock system preserved

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../tabs/dog_photos_tab.dart';
import '../tabs/dog_files_tab.dart';
import '../tabs/dog_notes_tab.dart';
import '../tabs/dog_correspondence_tab.dart';

import '../services/dog_lock_service.dart';
import '../pages/cards/spay_status_card.dart';

import 'people_detail_page.dart';

class DogDetailsPage extends StatefulWidget {
  final dynamic dogId;

  const DogDetailsPage({super.key, required this.dogId});

  @override
  State<DogDetailsPage> createState() => _DogDetailsPageState();
}

class _DogDetailsPageState extends State<DogDetailsPage> {

  final supabase = Supabase.instance.client;

  Map<String, dynamic>? dog;
  Map<String, dynamic>? originalDog;

  List<Map<String, dynamic>> allDogs = [];
  List<Map<String, dynamic>> allPeople = [];
  List<String> dogTypes = [];

  String? heroImageUrl;

  // inserted it here
  int heroImageVersion = DateTime.now().millisecondsSinceEpoch;

  bool loading = true;
  bool editMode = false;

  final nameController = TextEditingController();
  final alaController = TextEditingController();
  final microchipController = TextEditingController();

  String? selectedDogType;
  String? selectedSex;
  String? selectedDesexed;
  String? selectedMotherId;
  String? selectedFatherId;
  String? selectedOwnerId;
  DateTime? selectedSpayDue;

  @override
  void initState() {
    super.initState();
    loadDog();
  }

  Future loadDog() async {

    loading = true;
    setState(() {});

    final result = await supabase
        .from('dogs')
        .select()
        .eq('id', widget.dogId)
        .maybeSingle();

    if(result == null){
      loading = false;
      setState(() {});
      return;
    }

    dog = result;
    originalDog = Map<String, dynamic>.from(result);

    nameController.text = dog?['dog_name'] ?? '';
    alaController.text = dog?['dog_ala'] ?? '';
    microchipController.text = dog?['microchip'] ?? '';

    selectedDogType = dog?['dog_type'];
    selectedSex = dog?['sex'];
    selectedDesexed = dog?['desexed'];
    selectedMotherId = dog?['mother_id']?.toString();
    selectedFatherId = dog?['father_id']?.toString();
    selectedOwnerId = dog?['people_id']?.toString();

    if(dog?['spay_due'] != null){
      selectedSpayDue = DateTime.tryParse(dog!['spay_due']);
    }

    await loadLists();
    await loadHeroImage();

    loading = false;
    setState(() {});
  }

  Future loadLists() async {

    allDogs = List<Map<String,dynamic>>.from(
        await supabase.from('dogs').select('id, dog_name').order('dog_name'));

    allPeople = List<Map<String,dynamic>>.from(
        await supabase.from('people').select().order('first_name_1st'));

    final types = await supabase.from('dogs').select('dog_type');

    dogTypes = types
        .map((e)=>e['dog_type'].toString())
        .toSet()
        .toList()
      ..sort();
  }

  Future loadHeroImage() async {

    final photo = await supabase
        .from('dog_photos')
        .select('url')
        .eq('dog_id', widget.dogId)
        .limit(1);

    if (photo.isNotEmpty) {

      final fileName = photo.first['url'];

      final fullUrl =
          "https://phkwizyrpfzoecugpshb.supabase.co/storage/v1/object/public/dog_files/${widget.dogId}/photo/$fileName";

      print("Hero URL: $fullUrl");

      heroImageUrl = fullUrl;
    }
  }



  Future saveChanges() async {

    await supabase.from('dogs').update({

      'dog_name': nameController.text,
      'dog_ala': alaController.text,
      'microchip': microchipController.text,
      'dog_type': selectedDogType,
      'sex': selectedSex,
      'desexed': selectedDesexed,
      'mother_id': selectedMotherId,
      'father_id': selectedFatherId,
      'people_id': selectedOwnerId,
      'spay_due': selectedSpayDue?.toIso8601String()

    }).eq('id', dog!['id']);

    editMode = false;

    await loadDog();
  }

  void cancelChanges(){

    dog = Map<String,dynamic>.from(originalDog!);
    editMode = false;
    loadDog();
  }

  Future confirmSave() async {

    final result = await showDialog(

      context: context,

      builder:(_)=>AlertDialog(

        title:const Text("Save changes?"),

        actions:[

          TextButton(
            child:const Text("Cancel Changes"),
            onPressed:()=>Navigator.pop(context,"cancel"),
          ),

          TextButton(
            child:const Text("Continue Editing"),
            onPressed:()=>Navigator.pop(context,"continue"),
          ),

          ElevatedButton(
            child:const Text("Save Changes"),
            onPressed:()=>Navigator.pop(context,"save"),
          ),
        ],
      ),
    );

    if(result=="save") await saveChanges();

    if(result=="cancel") cancelChanges();
  }

  Future pickHeroImage() async {

    final picker = ImagePicker();

    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    final fileName = file.name;

    final storagePath =
        "${dog!['id']}/${dog!['dog_ala']}/photo/$fileName";

    // Upload to Supabase Storage
    await supabase.storage
        .from('dog_files')
        .upload(storagePath, File(file.path),
        fileOptions: const FileOptions(upsert: true));

    // Save ONLY filename in database
    await supabase
        .from('dog_photos')
        .insert({
          'dog_id': dog!['id'],
          'url': fileName,
          'description': dog!['dog_name']
        });

    await loadDog();
  }

  Future<String?> bottomSheetSelector({
    required String title,
    required List<Map<String,dynamic>> list,
    required String field,
    required String idField,
  }) async {

    String search="";

    return await showModalBottomSheet<String>(

      context: context,
      isScrollControlled:true,

      builder:(context){

        return StatefulBuilder(

          builder:(context,setModalState){

            final filtered=list.where((e)=>
                e[field].toString().toLowerCase().contains(search.toLowerCase())
            ).toList();

            return Padding(

              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom
              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children:[

                  Text(title, style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),

                  TextField(
                    decoration:const InputDecoration(hintText:"Search..."),
                    onChanged:(v)=>setModalState(()=>search=v),
                  ),

                  SizedBox(
                    height:400,
                    child:ListView.builder(

                      itemCount:filtered.length,

                      itemBuilder:(context,index){

                        final item=filtered[index];

                        return ListTile(
                          title:Text(item[field]),
                          onTap:()=>Navigator.pop(context,item[idField].toString()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget selectorField({
    required String label,
    required String? valueId,
    required List<Map<String,dynamic>> list,
    required String field,
    required String idField,
    required Function(String?) onSelected,
  }){

    final text=list.firstWhere(
        (e)=>e[idField].toString()==valueId,
        orElse:()=>{field:""})[field];

    if(!editMode){
      return Text("$label: $text");
    }

    return ListTile(
      title:Text(label),
      subtitle:Text(text ?? "Select"),
      onTap:() async {

        final result=await bottomSheetSelector(
            title:label,
            list:list,
            field:field,
            idField:idField
        );

        if(result!=null) onSelected(result);
      },
    );
  }

  @override
  Widget build(BuildContext context){

    if(loading){
      return const Scaffold(body:Center(child:CircularProgressIndicator()));
    }

    return DefaultTabController(

      length:4,

      child:Scaffold(

        appBar:AppBar(

          title:Text(nameController.text),

          actions:[

            IconButton(

              icon:Icon(dog!['locked']?Icons.lock:Icons.lock_open),

              onPressed:() async {

                if(!dog!['locked'] && editMode){

                  await confirmSave();
                }

                await DogLockService.toggleLock(
                    dogId:dog!['id'],
                    locked:dog!['locked']
                );

                await loadDog();
              },
            ),

            IconButton(

              icon:const Icon(Icons.edit),

              onPressed:dog!['locked']?null:(){

                editMode=!editMode;
                setState((){});
              },
            ),
          ],
        ),

        body:SingleChildScrollView(
          child:Column(
            children:[

              if (heroImageUrl != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: Image.network(
                        "https://phkwizyrpfzoecugpshb.supabase.co/storage/v1/object/public/dog_files/${dog!['id']}/${dog!['dog_ala']}/photo/hero.jpg?v=$heroImageVersion",

                        height: 250,
                        width: double.infinity,

                        fit: BoxFit.contain,

                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey[200],
                            child: const Icon(Icons.pets, size: 80),
                          );
                        },
                      )
                  ),
                ),
              ),



            Padding(

              padding:const EdgeInsets.all(12),

              child:Column(

                crossAxisAlignment:CrossAxisAlignment.start,

                children:[

                  editMode
                      ? TextField(controller:nameController)
                      : Text("Name: ${nameController.text}"),

                  editMode
                      ? TextField(controller:alaController)
                      : Text("ALA: ${alaController.text}"),

                  editMode
                      ? TextField(controller:microchipController)
                      : Text("Microchip: ${microchipController.text}"),

                  selectorField(
                      label:"Mother",
                      valueId:selectedMotherId,
                      list:allDogs,
                      field:"dog_name",
                      idField:"id",
                      onSelected:(v)=>setState(()=>selectedMotherId=v)
                  ),

                  selectorField(
                      label:"Father",
                      valueId:selectedFatherId,
                      list:allDogs,
                      field:"dog_name",
                      idField:"id",
                      onSelected:(v)=>setState(()=>selectedFatherId=v)
                  ),

                  selectorField(
                      label:"Owner",
                      valueId:selectedOwnerId,
                      list:allPeople,
                      field:"first_name_1st",
                      idField:"people_id",
                      onSelected:(v)=>setState(()=>selectedOwnerId=v)
                  ),

                  SpayStatusCard(dog:dog!, onUpdated:loadDog),
                ],
              ),
            ),

            const TabBar(
              tabs:[
                Tab(text:"Photos"),
                Tab(text:"Files"),
                Tab(text:"Notes"),
                Tab(text:"Correspondence"),
              ],
            ),

            SizedBox(
              height: 500,
              child: TabBarView(

                children:[
                  DogPhotosTab(
                    dogId: dog!['id'].toString(),
                    dogAla: dog!['dog_ala'] ?? '',
                    onHeroChanged: () {
                      setState(() {
                        heroImageVersion =
                            DateTime.now().millisecondsSinceEpoch;
                      });
                    },
                  ),
                  DogFilesTab(dogId:dog!['id']),
                  DogNotesTab(dogId:dog!['id']),
                  DogCorrespondenceTab(dogId:dog!['id']),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
