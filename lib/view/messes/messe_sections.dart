import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/messe.dart';
import 'package:voxbox/models/messe_section.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/services/messe_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/view/messes/section_chants.dart';

class MesseSectionsScreen extends StatefulWidget {
  final Messe messe;

  const MesseSectionsScreen({super.key, required this.messe});

  @override
  State<MesseSectionsScreen> createState() => _MesseSectionsScreenState();
}

class _MesseSectionsScreenState extends State<MesseSectionsScreen> {
  List<MesseSection> sections = [];
  bool loading = false;
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  void _loadSections() async {
    setState(() {
      loading = true;
    });

    try {
      var response = await MesseService.getMesseSections(widget.messe.id);
      if (response.error == null) {
        List<MesseSection> loadedSections = response.data as List<MesseSection>;
        
        // Si les chants ne sont pas chargés dans les sections, les charger séparément
        for (var section in loadedSections) {
          if (section.chants == null || section.chants!.isEmpty) {
            // Charger les chants pour cette section
            var chantsResponse = await MesseService.getSectionChants(section.id, messeId: section.messeId);
            if (chantsResponse.error == null && chantsResponse.data != null) {
              // Mettre à jour la section avec les chants chargés
              int sectionIndex = loadedSections.indexWhere((s) => s.id == section.id);
              if (sectionIndex != -1) {
                loadedSections[sectionIndex] = section.copyWith(
                  chants: chantsResponse.data as List<ChantDeMesse>,
                );
              }
            }
          }
        }
        
        setState(() {
          sections = loadedSections;
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
        ToastService.error(
          context,
          'Erreur: ${response.error}',
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      ToastService.error(
        context,
        'Erreur: $e',
      );
    }
  }

  void _syncSections() async {
    setState(() {
      syncing = true;
    });

    try {
      // Recharger les sections
      _loadSections();
      ToastService.success(
        context,
        'Sections synchronisées',
      );
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

  IconData _getIconForSection(String sectionName) {
    String name = sectionName.toLowerCase();
    if (name.contains('kyrié')) return Icons.self_improvement;
    if (name.contains('gloria')) return Icons.celebration;
    if (name.contains('sanctus')) return Icons.church;
    if (name.contains('agnus')) return Icons.favorite;
    return Icons.music_note;
  }

  void _openSection(MesseSection section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionChantsScreen(section: section),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: widget.messe.nom,
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
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    MesseSection section = sections[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 4,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse(widget.messe.couleur.replaceAll('#', '0xFF'))),
                          child: Icon(
                            _getIconForSection(section.nom),
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
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '${section.chants?.length ?? 0} chant${(section.chants?.length ?? 0) > 1 ? 's' : ''}',
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