import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/chant_section.dart';
import 'package:voxbox/services/chant_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/view/chants/chant_sections.dart';

class ChantsScreen extends StatefulWidget {
  const ChantsScreen({super.key});

  @override
  State<ChantsScreen> createState() => _ChantsScreenState();
}

class _ChantsScreenState extends State<ChantsScreen> {
  List<ChantSection> sections = [];
  bool loading = false;
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      loading = true;
    });

    try {
      // Charger les sections depuis le serveur
      var sectionsResponse = await ChantService.getSectionsFromServer();
      if (sectionsResponse.error == null) {
        setState(() {
          sections = sectionsResponse.data as List<ChantSection>;
          loading = false;
        });
      } else {
        // En cas d'erreur, charger depuis le stockage local
        List<ChantSection> localSections = await ChantService.getLocalSections();
        setState(() {
          sections = localSections;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  void _syncSections() async {
    setState(() {
      syncing = true;
    });

    try {
      var response = await ChantService.syncAllSections();
      if (response.error == null) {
        setState(() {
          sections = response.data!;
        });
        ToastService.success(
          context,
          'Sections synchronisées avec succès',
        );
      } else {
        ToastService.error(
          context,
          'Erreur de synchronisation: ${response.error}',
        );
      }
    } catch (e) {
      ToastService.error(
        context,
        'Erreur: $e',
      );
    } finally {
      setState(() {
        syncing = false;
      });
    }
  }

  IconData _getIconForSection(String iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note;
      case 'folder':
        return Icons.folder;
      case 'library_music':
        return Icons.library_music;
      default:
        return Icons.music_note;
    }
  }

  Color _getColorForSection(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return AppConstance.primary;
    }
  }

  void _openSection(ChantSection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChantSectionsScreen(section: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MyText(
          text: 'Mes Chants',
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: syncing ? null : _syncSections,
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
          : sections.isEmpty
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
                        'Aucune section trouvée',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Appuyez sur le bouton de synchronisation pour charger les sections',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    ChantSection section = sections[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColorForSection(section.couleur),
                          child: Icon(
                            _getIconForSection(section.icone),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          section.nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (section.description != null)
                              Text(
                                section.description!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '${section.chantsCount} chant${section.chantsCount > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _openSection(section),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _syncSections,
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
