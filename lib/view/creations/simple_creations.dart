import 'dart:io';
import 'package:flutter/material.dart';
import 'package:voxbox/services/global_recorder_service.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/services/photo_service.dart';
import 'package:voxbox/services/creation_folder_service.dart';
import 'package:voxbox/models/creation_folder.dart';
import 'package:voxbox/widgets/voice_recorder_button.dart';
import 'package:voxbox/view/creations/recordings_history_sheet.dart';
import 'package:voxbox/view/creations/folders_screen.dart';
import 'package:voxbox/functions/appconstants.dart';

/// Page Créations simplifiée avec enregistrement intuitif
class SimpleCreationsScreen extends StatefulWidget {
  const SimpleCreationsScreen({super.key});

  @override
  State<SimpleCreationsScreen> createState() => _SimpleCreationsScreenState();
}

class _SimpleCreationsScreenState extends State<SimpleCreationsScreen> {
  final GlobalRecorderService _recorderService = GlobalRecorderService();
  final PhotoService _photoService = PhotoService();
  final CreationFolderService _folderService = CreationFolderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstance.primary,
                AppConstance.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
            ),
            title: const Text(
              'Créations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Bouton Mes dossiers
              IconButton(
                icon: const Icon(Icons.folder_open, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FoldersScreen()),
                  );
                },
                tooltip: 'Mes dossiers',
              ),
              // Badge d'enregistrements
              FutureBuilder<List<AudioRecording>>(
                future: _recorderService.getRecordings(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.audiotrack, color: Colors.white),
                          onPressed: () {},
                          tooltip: '${snapshot.data!.length} enregistrement(s)',
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${snapshot.data!.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            // Zone principale
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône et instructions
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white70,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Enregistrement rapide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Maintenez le bouton pour enregistrer\nGlissez vers le haut pour verrouiller',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Bouton d'enregistrement
                    VoiceRecorderButton(
                      onRecordingComplete: () {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enregistrement sauvegardé'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Liste des créations récentes (audio et photos)
            FutureBuilder<Map<String, dynamic>>(
              future: _loadRecentCreations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final data = snapshot.data ?? {};
                final recordings = data['recordings'] as List<AudioRecording>? ?? [];
                final photos = data['photos'] as List<PhotoItem>? ?? [];

                if (recordings.isEmpty && photos.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Aucune création pour le moment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                // Afficher les 5 dernières créations (audio + photos)
                final recentRecordings = recordings.take(3).toList();
                final recentPhotos = photos.take(2).toList();

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: const Text(
                              'Créations récentes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recordings.length > 3 || photos.length > 2)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      appBar: AppBar(
                                        title: const Text('Tous les enregistrements'),
                                        backgroundColor: AppConstance.primary,
                                      ),
                                      body: RecordingsHistorySheet(
                                        scrollController: ScrollController(),
                                        onClose: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Voir tout'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Photos
                      if (recentPhotos.isNotEmpty) ...[
                        ...recentPhotos.map((photo) => _buildPhotoTile(photo)),
                        if (recentRecordings.isNotEmpty) const SizedBox(height: 12),
                      ],
                      // Enregistrements
                      if (recentRecordings.isNotEmpty)
                      ...recentRecordings.map((recording) => _buildRecordingTile(recording)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePhoto,
        backgroundColor: AppConstance.primary,
        child: const Icon(Icons.camera_alt, color: Colors.white),
        tooltip: 'Prendre une photo',
      ),
    );
  }

  Future<Map<String, dynamic>> _loadRecentCreations() async {
    final recordings = await _recorderService.getRecordings();
    final photos = await _photoService.getPhotos();
    return {
      'recordings': recordings,
      'photos': photos,
    };
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _photoService.takePhoto();
      if (photo != null && mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo sauvegardée'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPhotoTile(PhotoItem photo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Miniature de la photo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(photo.path),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppConstance.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.image,
                    color: AppConstance.secondary,
                    size: 24,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  photo.formattedFileSize,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            onSelected: (value) async {
              if (value == 'move_to_folder') {
                await _movePhotoToFolder(photo);
              } else if (value == 'delete') {
                await _deletePhoto(photo);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'move_to_folder',
                child: Row(
                  children: [
                    Icon(Icons.folder, color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Text('Déplacer vers un dossier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Text('Supprimer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _movePhotoToFolder(PhotoItem photo) async {
    final folders = await _folderService.getFolders();

    if (folders.isEmpty) {
      final createFolder = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aucun dossier'),
          content: const Text('Vous n\'avez aucun dossier. Voulez-vous en créer un maintenant ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      );

      if (createFolder == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FoldersScreen()),
        );
        final updatedFolders = await _folderService.getFolders();
        if (updatedFolders.isNotEmpty) {
          await _showPhotoFolderSelection(photo, updatedFolders);
        }
      }
      return;
    }

    await _showPhotoFolderSelection(photo, folders);
  }

  Future<void> _showPhotoFolderSelection(PhotoItem photo, List<CreationFolder> folders) async {
    final selectedFolder = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner un dossier'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ListTile(
                leading: const Icon(Icons.folder, color: Colors.blue),
                title: Text(folder.name),
                subtitle: folder.description != null ? Text(folder.description!) : null,
                onTap: () => Navigator.pop(context, folder.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (selectedFolder != null) {
      try {
        final file = File(photo.path);
        final fileSize = file.existsSync() ? file.lengthSync() : null;

        final success = await _folderService.movePhotoToFolder(
          selectedFolder,
          photo.path,
          photo.name,
          fileSize: fileSize,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo déplacée vers le dossier'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() {});
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du déplacement'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deletePhoto(PhotoItem photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${photo.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _photoService.deletePhoto(photo.path);
      if (success && mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo supprimée'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildRecordingTile(AudioRecording recording) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstance.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.music_note,
              color: AppConstance.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recording.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(recording.duration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            onPressed: () {
              // TODO: Jouer l'enregistrement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lecture en cours de développement'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
