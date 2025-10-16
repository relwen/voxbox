import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/view/messes/add_files_to_chant.dart';
import 'package:voxbox/services/chant_service.dart';
import 'package:voxbox/services/file_upload_service.dart';

class ChantDetailsScreen extends StatefulWidget {
  final ChantDeMesse chant;

  const ChantDetailsScreen({super.key, required this.chant});

  @override
  State<ChantDetailsScreen> createState() => _ChantDetailsScreenState();
}

class _ChantDetailsScreenState extends State<ChantDetailsScreen> with SingleTickerProviderStateMixin {
  bool loading = false;
  late TabController _tabController;
  ChantDeMesse? _currentChant;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _currentChant = widget.chant;
    _loadChantData();
  }

  Future<void> _loadChantData() async {
    setState(() {
      loading = true;
    });

    try {
      // D'abord charger les données locales (avec fichiers en attente)
      final localChant = await ChantService.getLocalChant(widget.chant.id);
      if (localChant != null) {
        setState(() {
          _currentChant = localChant;
        });
      }

      // Ensuite essayer de synchroniser avec le serveur
      final response = await ChantService.syncChant(widget.chant.id);
      if (response.error == null && response.data != null) {
        setState(() {
          _currentChant = response.data as ChantDeMesse;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données du chant: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentChant == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chargement...'),
          backgroundColor: AppConstance.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: _currentChant!.titre,
          color: Colors.white,
          size: 18,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        actions: [
          FutureBuilder<bool>(
            future: ChantService.hasPendingFiles(_currentChant!.id),
            builder: (context, snapshot) {
              final hasPending = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  hasPending ? Icons.cloud_upload : Icons.cloud_done,
                  color: hasPending ? Colors.orange : Colors.green,
                ),
                onPressed: _loadChantData,
                tooltip: hasPending ? 'Fichiers en attente de sync' : 'Synchronisé',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadChantData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _addFiles(),
            tooltip: 'Ajouter des fichiers',
          ),
          
        ],
      ),
      body: Column(
        children: [
          // En-tête du chant
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppConstance.primary,
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentChant!.titre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentChant!.description != null)
                        Text(
                          _currentChant!.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // TabBar pour les pupitres
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppConstance.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppConstance.primary,
            tabs: const [
              Tab(text: 'Soprano', icon: Icon(Icons.person, size: 16)),
              Tab(text: 'Alto', icon: Icon(Icons.person, size: 16)),
              Tab(text: 'Ténor', icon: Icon(Icons.person, size: 16)),
              Tab(text: 'Basse', icon: Icon(Icons.person, size: 16)),
              Tab(text: 'Tutti', icon: Icon(Icons.group, size: 16)),
              Tab(text: 'Général', icon: Icon(Icons.folder, size: 16)),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPupitreTab('Soprano', _currentChant!.sopranoUrls, Colors.pink),
                _buildPupitreTab('Alto', _currentChant!.altoUrls, Colors.orange),
                _buildPupitreTab('Ténor', _currentChant!.tenorUrls, Colors.blue),
                _buildPupitreTab('Basse', _currentChant!.basseUrls, Colors.brown),
                _buildPupitreTab('Tutti', _currentChant!.tuttiUrls, Colors.purple),
                _buildGeneralTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPupitreTab(String pupitreName, List<String> files, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du pupitre
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    child: Icon(
                      pupitreName == 'Tutti' ? Icons.group : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pupitre $pupitreName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${files.length} fichier(s) disponible(s)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: color),
                    onPressed: () => _addFilesToPupitre(pupitreName),
                    tooltip: 'Ajouter des fichiers',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des fichiers
          if (files.isEmpty)
            _buildEmptyState(pupitreName, color)
          else
            ...files.asMap().entries.map((entry) {
              int index = entry.key;
              String file = entry.value;
              return _buildFileItem(file, index + 1, color);
            }),
        ],
      ),
    );
  }

  Widget _buildFileItem(String file, int index, Color color) {
    return FutureBuilder<bool>(
      future: _isFilePending(file),
      builder: (context, snapshot) {
        final isPending = snapshot.data ?? false;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isPending ? Colors.orange : Colors.grey.shade300,
              width: isPending ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isPending ? Colors.orange.withValues(alpha: 0.1) : null,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Icon(
                    _getFileIcon(file),
                    color: color,
                    size: 20,
                  ),
                  if (isPending)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Fichier $index',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isPending ? Icons.cloud_upload : Icons.cloud_done,
                          size: 12,
                          color: isPending ? Colors.orange : Colors.green,
                        ),
                      ],
                    ),
                    Text(
                      file.split('/').last,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    if (isPending)
                      const Text(
                        'En attente de synchronisation',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Colors.blue),
                onPressed: () => _downloadFile(file),
                tooltip: 'Télécharger',
              ),
              if (_isAudioFile(file))
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: () => _playAudio(file),
                  tooltip: 'Lire',
                ),
              if (_isPdfFile(file))
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.orange),
                  onPressed: () => _viewPdf(file),
                  tooltip: 'Voir',
                ),
              if (_isImageFile(file))
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.purple),
                  onPressed: () => _viewImage(file),
                  tooltip: 'Voir',
                ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _isFilePending(String filePath) async {
    try {
      final pendingFiles = await ChantService.getPendingFiles(_currentChant!.id);
      return pendingFiles.any((file) => 
        file['filePath'] == filePath && file['synced'] != true);
    } catch (e) {
      return false;
    }
  }

  Widget _buildEmptyState(String pupitreName, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            pupitreName == 'Tutti' ? Icons.group : Icons.person,
            color: Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun fichier pour le pupitre $pupitreName',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur + pour ajouter des fichiers',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fichiers généraux (audio, PDF, images)
          if (_currentChant!.audioFiles?.isNotEmpty == true || _currentChant!.audioPath != null)
            _buildFileSection(
              title: 'Fichiers Audio',
              icon: Icons.audiotrack,
              color: Colors.green,
              files: _currentChant!.audioFiles ?? (_currentChant!.audioPath != null ? [_currentChant!.audioPath!] : []),
            ),

          const SizedBox(height: 16),

          if (_currentChant!.pdfFiles?.isNotEmpty == true || _currentChant!.pdfPath != null)
            _buildFileSection(
              title: 'Partitions PDF',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              files: _currentChant!.pdfFiles ?? (_currentChant!.pdfPath != null ? [_currentChant!.pdfPath!] : []),
            ),

          const SizedBox(height: 16),

          if (_currentChant!.imageFiles?.isNotEmpty == true || _currentChant!.imagePath != null)
            _buildFileSection(
              title: 'Images',
              icon: Icons.image,
              color: Colors.blue,
              files: _currentChant!.imageFiles ?? (_currentChant!.imagePath != null ? [_currentChant!.imagePath!] : []),
            ),

          const SizedBox(height: 20),

          // Informations du chant
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Ordre', _currentChant!.ordre.toString()),
                  _buildInfoRow('Statut', _currentChant!.active ? 'Actif' : 'Inactif'),
                  _buildInfoRow('Créé le', _formatDate(_currentChant!.createdAt)),
                  _buildInfoRow('Modifié le', _formatDate(_currentChant!.updatedAt)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> files,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${files.length}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...files.asMap().entries.map((entry) {
              int index = entry.key;
              String file = entry.value;
              return _buildFileItem(file, index + 1, color);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String file) {
    if (_isAudioFile(file)) return Icons.audiotrack;
    if (_isPdfFile(file)) return Icons.picture_as_pdf;
    if (_isImageFile(file)) return Icons.image;
    return Icons.insert_drive_file;
  }

  bool _isAudioFile(String file) {
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg'];
    return audioExtensions.any((ext) => file.toLowerCase().endsWith(ext));
  }

  bool _isPdfFile(String file) {
    return file.toLowerCase().endsWith('.pdf');
  }

  bool _isImageFile(String file) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    return imageExtensions.any((ext) => file.toLowerCase().endsWith(ext));
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _downloadFile(String file) async {
    setState(() {
      loading = true;
    });

    try {
      final fileName = file.split('/').last;
      final success = await ChantService.downloadFile(file, fileName);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fichier téléchargé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du téléchargement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _playAudio(String file) {
    // TODO: Implémenter la lecture audio
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lecture de $file...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewPdf(String file) {
    // TODO: Implémenter la visualisation PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de $file...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _viewImage(String file) {
    // TODO: Implémenter la visualisation d'image
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de $file...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _addFiles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFilesToChantScreen(chant: _currentChant!),
      ),
    ).then((_) {
      // Recharger les données après ajout de fichiers
      _loadChantData();
    });
  }

  void _addFilesToPupitre(String pupitreName) async {
    try {
      // Sélectionner des fichiers pour le pupitre
      List<File> selectedFiles = [];
      
      // Afficher un dialogue pour choisir le type de fichier
      final fileType = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ajouter des fichiers pour $pupitreName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.audiotrack, color: Colors.green),
                title: const Text('Fichiers Audio'),
                onTap: () => Navigator.pop(context, 'audio'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Fichiers PDF'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('Images'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
            ],
          ),
        ),
      );

      if (fileType != null) {
        setState(() {
          loading = true;
        });

        // Sélectionner les fichiers selon le type
        switch (fileType) {
          case 'audio':
            selectedFiles = await FileUploadService.selectMultipleAudioFiles();
            break;
          case 'pdf':
            selectedFiles = await FileUploadService.selectMultiplePdfFiles();
            break;
          case 'image':
            selectedFiles = await FileUploadService.selectMultipleImageFiles();
            break;
        }

        if (selectedFiles.isNotEmpty) {
          // Sauvegarder localement d'abord
          final filePaths = selectedFiles.map((file) => file.path).toList();
          await ChantService.addPendingFiles(
            _currentChant!.id,
            fileType,
            filePaths,
            pupitreName,
          );

          // Mettre à jour l'affichage immédiatement
          _loadChantData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${selectedFiles.length} fichier(s) ajouté(s) localement pour $pupitreName'),
                backgroundColor: Colors.blue,
              ),
            );
          }

          // Essayer de synchroniser en arrière-plan
          try {
            final response = await ChantService.addPupitreFiles(
              _currentChant!.id,
              pupitreName,
              selectedFiles,
            );

            if (response.error == null) {
              // Marquer comme synchronisé
              await ChantService.markFilesAsSynced(_currentChant!.id, filePaths);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fichiers synchronisés avec le serveur'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fichiers ajoutés localement. Synchronisation en attente.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fichiers ajoutés localement. Synchronisation en attente.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        loading = false;
      });
    }
  }
}
