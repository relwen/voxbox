import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/chant_section.dart';
import 'package:voxbox/services/chant_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/view/chants/chant_sections.dart';
import 'package:voxbox/widgets/offline_indicator.dart';
import 'package:voxbox/widgets/shimmer_loading.dart';

import 'package:voxbox/models/user.dart';

class ChantsScreen extends StatefulWidget {
  const ChantsScreen({super.key});

  @override
  State<ChantsScreen> createState() => _ChantsScreenState();
}

class _ChantsScreenState extends State<ChantsScreen> {
  List<ChantSection> sections = [];
  bool loading = false;
  bool syncing = false;
  User? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadData();
  }

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      setState(() {
        user = User.fromJson(jsonDecode(userString));
      });
    }
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
        List<ChantSection> localSections =
            await ChantService.getLocalSections();
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
    ).then((_) =>
        _loadData()); // Recharger au retour pour mettre à jour les comptes
  }

  void _showAddSectionDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle section de chants'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la section',
                hintText: 'Ex: Chants d\'entrée',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _createSection(
                    nameController.text.trim(), descController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstance.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _createSection(String nom, String? description) async {
    setState(() {
      loading = true;
    });

    try {
      var response = await ChantService.createSection(nom, description);
      if (response.error == null) {
        ToastService.success(context, 'Section créée avec succès');
        _loadData();
      } else {
        ToastService.error(context, 'Erreur: ${response.error}');
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
      setState(() {
        loading = false;
      });
    }
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddSectionDialog,
            tooltip: 'Ajouter une section',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: syncing ? null : _syncSections,
            tooltip: 'Synchroniser',
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: loading
                ? const ShimmerListLoading()
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
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditSectionDialog(section);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmDialog(section);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Modifier'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Supprimer',
                                          style: TextStyle(color: Colors.red)),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _openSection(section),
                              onLongPress: () => _showEditSectionDialog(section),
                            ),
                          );
                        },
                      ),
          ),
        ],
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

  void _showEditSectionDialog(ChantSection section) {
    final TextEditingController nameController =
        TextEditingController(text: section.nom);
    final TextEditingController descController =
        TextEditingController(text: section.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la section'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom de la section',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _updateSection(section.id, nameController.text.trim(),
                    descController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstance.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _updateSection(int id, String nom, String? description) async {
    setState(() {
      loading = true;
    });

    try {
      var response = await ChantService.updateSection(id, nom, description);
      if (response.error == null) {
        ToastService.success(context, 'Section mise à jour avec succès');
        _loadData();
      } else {
        ToastService.error(context, 'Erreur: ${response.error}');
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
      setState(() {
        loading = false;
      });
    }
  }

  void _showDeleteConfirmDialog(ChantSection section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la section'),
        content: Text(
            'Voulez-vous vraiment supprimer la section "${section.nom}" et TOUTES ses partitions ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSection(section.id);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteSection(int id) async {
    setState(() {
      loading = true;
    });

    try {
      var response = await ChantService.deleteSection(id);
      if (response.error == null) {
        ToastService.success(context, 'Section supprimée avec succès');
        _loadData();
      } else {
        ToastService.error(context, 'Erreur: ${response.error}');
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      ToastService.error(context, 'Erreur: $e');
      setState(() {
        loading = false;
      });
    }
  }
}
