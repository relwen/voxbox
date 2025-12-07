import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/models/vocalise_section.dart';
import 'package:voxbox/services/vocalise_service.dart';
import 'package:voxbox/view/vocalize/vocalise_details.dart';
import 'package:voxbox/view/vocalize/add_vocalise.dart';

class VocaliseListScreen extends StatefulWidget {
  final VocaliseSection section;

  const VocaliseListScreen({super.key, required this.section});

  @override
  State<VocaliseListScreen> createState() => _VocaliseListScreenState();
}

class _VocaliseListScreenState extends State<VocaliseListScreen> {
  List<Vocalise> vocalises = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadVocalises();
  }

  void _loadVocalises() async {
    setState(() {
      loading = true;
    });

    try {
      print('🔄 Chargement des vocalises pour la section ${widget.section.id} (${widget.section.nom})');
      var response = await VocaliseService.getVocalisesBySection(widget.section.id);
      
      if (response.error == null) {
        if (response.data != null) {
          final loadedVocalises = response.data as List<Vocalise>;
          print('✅ ${loadedVocalises.length} vocalise(s) chargée(s)');
          setState(() {
            vocalises = loadedVocalises;
            loading = false;
          });
        } else {
          print('⚠️ Aucune vocalise retournée (data est null)');
          setState(() {
            vocalises = [];
            loading = false;
          });
        }
      } else {
        print('❌ Erreur lors du chargement: ${response.error}');
        setState(() {
          loading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Exception lors du chargement des vocalises: $e');
      print('📚 Stack: $stackTrace');
      setState(() {
        loading = false;
      });
    }
  }

  void _openVocaliseDetails(Vocalise vocalise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VocaliseDetailsScreen(vocalise: vocalise),
      ),
    );
  }

  Widget _buildVocaliseCard(Vocalise vocalise) {
    // Compter le nombre de fichiers
    int fileCount = 0;
    if (vocalise.audioFiles != null) fileCount += vocalise.audioFiles!.length;
    if (vocalise.pdfFiles != null) fileCount += vocalise.pdfFiles!.length;
    if (vocalise.imageFiles != null) fileCount += vocalise.imageFiles!.length;
    if (vocalise.sopranoFiles != null) fileCount += vocalise.sopranoFiles!.length;
    if (vocalise.altoFiles != null) fileCount += vocalise.altoFiles!.length;
    if (vocalise.tenorFiles != null) fileCount += vocalise.tenorFiles!.length;
    if (vocalise.basseFiles != null) fileCount += vocalise.basseFiles!.length;
    if (vocalise.tuttiFiles != null) fileCount += vocalise.tuttiFiles!.length;

    // Fichiers uniques (legacy)
    if (fileCount == 0) {
      if (vocalise.audioPath != null) fileCount++;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstance.primary,
          child: const Icon(
            Icons.music_note,
            color: Colors.white,
          ),
        ),
        title: Text(
          vocalise.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vocalise.description != null)
              Text(
                vocalise.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    vocalise.voicePart,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppConstance.primary.withValues(alpha: 0.1),
                ),
                const SizedBox(width: 8),
                if (fileCount > 0)
                  Chip(
                    label: Text(
                      '$fileCount fichier${fileCount > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _openVocaliseDetails(vocalise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: widget.section.nom,
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVocaliseScreen(section: widget.section),
                ),
              );
              if (result == true) {
                _loadVocalises();
              }
            },
            tooltip: 'Ajouter une vocalise',
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: SpinKitFadingCircle(
                color: Colors.blue,
                size: 50.0,
              ),
            )
          : vocalises.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune vocalise disponible',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: vocalises.length,
                  itemBuilder: (context, index) {
                    final vocalise = vocalises[index];
                    return _buildVocaliseCard(vocalise);
                  },
                ),
    );
  }
}
