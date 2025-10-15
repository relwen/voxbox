import 'dart:convert';
import 'dart:io';

// import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/api_response.dart';
import 'package:voxbox/services/messe_service.dart';
import 'package:voxbox/widgets/audio_recorder.dart';

class AddMesseScreen extends StatefulWidget {
  const AddMesseScreen({super.key});

  @override
  State<AddMesseScreen> createState() => _AddMesseScreenState();
}

class _AddMesseScreenState extends State<AddMesseScreen> with SingleTickerProviderStateMixin {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  
  User? currentUser;
  String? selectedVoicePart;
  bool loading = false;
  late TabController _tabController;
  
  final List<String> voiceParts = [
    'Basse',
    'Ténor',
    'Alto',
    'Soprano',
    'Tutti'
  ];

  // Sous-sections de la messe
  final List<String> messeSections = [
    'Kyrie',
    'Gloria',
    'Credo',
    'Sanctus',
    'Agnus Dei',
    'Communion'
  ];

  // Contrôleurs pour chaque section
  Map<String, TextEditingController> writtenPartitionControllers = {};
  Map<String, File?> musicalPartitionFiles = {};
  File? audioFile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: messeSections.length, vsync: this);
    getCurrentUser();
    initializeControllers();
  }

  void initializeControllers() {
    for (String section in messeSections) {
      writtenPartitionControllers[section] = TextEditingController();
      musicalPartitionFiles[section] = null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in writtenPartitionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userString = prefs.getString('user');
    if (userString != null) {
      Map<String, dynamic> userMap = jsonDecode(userString);
      setState(() {
        currentUser = User.fromJson(userMap);
        selectedVoicePart = currentUser?.voicePart ?? 'Basse';
      });
    }
  }

  Future<void> pickMusicalPartition(String section) async {
    // Version simplifiée pour éviter les problèmes de compilation
    // FilePickerResult? result = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['pdf'],
    // );

    // if (result != null) {
    //   setState(() {
    //     musicalPartitionFiles[section] = File(result.files.single.path!);
    //   });
    // }
    
    // Simulation pour le test
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fonctionnalité de sélection de fichier temporairement désactivée'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> submitForm() async {
    if (titleController.text.isEmpty || 
        descriptionController.text.isEmpty || 
        dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    // Préparer les sections avec les données
    List<Map<String, dynamic>> sectionsData = [];
    for (String section in messeSections) {
      sectionsData.add({
        'name': section,
        'written_partition': writtenPartitionControllers[section]?.text ?? '',
        'musical_partition': musicalPartitionFiles[section]?.path,
        'audio_file': audioFile?.path,
      });
    }

    ApiResponse response = await MesseService.createMesse(
      title: titleController.text,
      description: descriptionController.text,
      date: dateController.text,
      voicePart: selectedVoicePart ?? 'Basse',
      sections: sectionsData,
    );

    setState(() {
      loading = false;
    });

    if (response.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Messe ajoutée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      print('Erreur lors de l\'ajout de la messe: ${response.error}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${response.error ?? 'Erreur lors de l\'ajout'}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Widget buildSectionTab(String section) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partition écrite pour $section',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: writtenPartitionControllers[section],
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Entrez la partition écrite pour $section...',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),

          Text(
            'Partition musicale (PDF) pour $section',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => pickMusicalPartition(section),
              icon: Icon(Icons.upload_file),
              label: Text(
                musicalPartitionFiles[section] != null 
                    ? musicalPartitionFiles[section]!.path.split('/').last
                    : 'Choisir un fichier PDF pour $section',
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 16),

            // Enregistrement audio
            Text(
              'Enregistrement audio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: VoiceRecorderWidget(
                onRecordingComplete: (File recordedFile) {
                  setState(() {
                    audioFile = recordedFile;
                  });
                },
                initialAudioPath: audioFile?.path,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ajouter une messe"),
        backgroundColor: theme,
        foregroundColor: Colors.white,
        actions: [
          if (loading)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: SpinKitCircle(
                color: Colors.white,
                size: 20.0,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Informations générales de la messe
          Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Titre de la messe *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Messe Akan',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Description *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Description de la messe',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Date *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Pupitre *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedVoicePart,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: voiceParts.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedVoicePart = newValue;
                    });
                  },
                ),
              ],
            ),
          ),

          // Tabs pour les sections de la messe
          Container(
            color: Colors.grey[100],
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: theme,
              unselectedLabelColor: Colors.grey,
              tabs: messeSections.map((section) => Tab(text: section)).toList(),
            ),
          ),

          // Contenu des tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: messeSections.map((section) => buildSectionTab(section)).toList(),
            ),
          ),

          // Bouton de soumission
          Container(
            padding: EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstance.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Ajouter la messe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 