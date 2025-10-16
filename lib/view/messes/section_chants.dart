import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/messe_section.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/services/messe_service.dart';
import 'package:voxbox/view/messes/chant_details.dart';

class SectionChantsScreen extends StatefulWidget {
  final MesseSection section;

  const SectionChantsScreen({
    super.key,
    required this.section,
  });

  @override
  State<SectionChantsScreen> createState() => _SectionChantsScreenState();
}

class _SectionChantsScreenState extends State<SectionChantsScreen> {
  List<ChantDeMesse> chants = [];
  bool loading = false;
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _loadChants();
  }

  Future<void> _loadChants() async {
    setState(() {
      loading = true;
    });

    try {
      // D'abord charger depuis le cache local (avec fichiers ajoutés)
      final cachedChants = await MesseService.getSectionChantsFromCache(widget.section.id);
      if (cachedChants.isNotEmpty) {
        setState(() {
          chants = cachedChants;
          loading = false;
        });
      }

      // Ensuite essayer de synchroniser avec le serveur
      var response = await MesseService.getSectionChants(widget.section.id);
      if (response.error == null) {
        setState(() {
          chants = response.data as List<ChantDeMesse>;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${response.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _syncChants() async {
    setState(() {
      syncing = true;
    });

    try {
      await _loadChants();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chants synchronisés'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        syncing = false;
      });
    }
  }

  Future<void> _downloadAudio(ChantDeMesse chant) async {
    try {
      bool success = await MesseService.downloadAudio(chant);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio téléchargé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du téléchargement audio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadPdf(ChantDeMesse chant) async {
    try {
      bool success = await MesseService.downloadPdf(chant);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF téléchargé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du téléchargement PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getIconData(String? fileType) {
    switch (fileType) {
      case 'audio':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'image':
        return Icons.image;
      default:
        return Icons.music_note;
    }
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _openChantDetails(ChantDeMesse chant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChantDetailsScreen(chant: chant),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: syncing ? null : _syncChants,
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
          : chants.isEmpty
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
                        'Aucun chant trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chants.length,
                  itemBuilder: (context, index) {
                    ChantDeMesse chant = chants[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorFromHex('#2196F3'),
                          child: Icon(
                            _getIconData('music'),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          chant.titre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (chant.description != null)
                              Text(
                                chant.description!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (chant.audioPath != null)
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                                    onPressed: () => _downloadAudio(chant),
                                    tooltip: 'Télécharger audio',
                                  ),
                                if (chant.pdfPath != null)
                                  IconButton(
                                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                    onPressed: () => _downloadPdf(chant),
                                    tooltip: 'Télécharger PDF',
                                  ),
                                if (chant.imagePath != null)
                                  IconButton(
                                    icon: const Icon(Icons.image, color: Colors.blue),
                                    onPressed: () {
                                      // TODO: Implémenter la visualisation d'image
                                    },
                                    tooltip: 'Voir image',
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _openChantDetails(chant),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _syncChants,
        backgroundColor: AppConstance.primary,
        child: syncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.sync, color: Colors.white),
      ),
    );
  }
}
