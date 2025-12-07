import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/models/chorale_pupitre.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/chorale_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/services/global_audio_player_service.dart';
import 'package:voxbox/services/pdf_service.dart';
import 'package:voxbox/services/local_file_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class VocaliseDetailsScreen extends StatefulWidget {
  final Vocalise vocalise;

  const VocaliseDetailsScreen({super.key, required this.vocalise});

  @override
  State<VocaliseDetailsScreen> createState() => _VocaliseDetailsScreenState();
}

class _VocaliseDetailsScreenState extends State<VocaliseDetailsScreen> with SingleTickerProviderStateMixin {
  bool loading = false;
  TabController? _tabController;
  List<ChoralePupitre> _pupitres = [];
  int? _choraleId;
  Map<String, FileDownloadStatus> _fileStatuses = {};
  Map<String, bool> _downloadingFiles = {};
  final GlobalAudioPlayerService _audioPlayerService = GlobalAudioPlayerService();

  @override
  void initState() {
    super.initState();
    _loadPupitres();
    _checkFilesStatus();
  }

  Future<void> _checkFilesStatus() async {
    // Vérifier le statut de tous les fichiers
    final allFiles = <String>[];
    if (widget.vocalise.pdfFiles != null) allFiles.addAll(widget.vocalise.pdfUrls);
    if (widget.vocalise.imageFiles != null) allFiles.addAll(widget.vocalise.imageUrls);
    if (widget.vocalise.audioFiles != null) allFiles.addAll(widget.vocalise.audioUrls);

    final statuses = <String, FileDownloadStatus>{};
    for (var file in allFiles) {
      final status = await LocalFileService.getFileStatus(file);
      statuses[file] = status;
    }

    if (mounted) {
      setState(() {
        _fileStatuses = statuses;
      });
    }
  }

  Future<void> _loadPupitres() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userString = prefs.getString('user');
      if (userString != null) {
        Map<String, dynamic> userMap = jsonDecode(userString);
        User user = User.fromJson(userMap);
        _choraleId = user.choraleId;

        if (_choraleId != null) {
          final response = await ChoraleService.getPupitres(_choraleId!);
          if (response.error == null && response.data != null) {
            setState(() {
              _pupitres = response.data as List<ChoralePupitre>;
              _tabController?.dispose();
              _tabController = TabController(length: _pupitres.length + 1, vsync: this);
            });
          }
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des pupitres: $e');
      setState(() {
        _pupitres = [];
        _tabController?.dispose();
        _tabController = TabController(length: 1, vsync: this);
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<String> _getFilesForPupitre(int pupitreId) {
    // Récupérer le nom du pupitre depuis la liste des pupitres
    final pupitre = _pupitres.firstWhere(
      (p) => p.id == pupitreId,
      orElse: () => _pupitres.first,
    );
    final pupitreNom = pupitre.nom.toLowerCase();

    List<String> files = [];

    // Chercher les fichiers spécifiques au pupitre
    if (pupitreNom.contains('soprano') || pupitreNom.contains('soprane')) {
      if (widget.vocalise.sopranoFiles != null && widget.vocalise.sopranoFiles!.isNotEmpty) {
        files.addAll(widget.vocalise.sopranoUrls);
      }
    } else if (pupitreNom.contains('alto') || pupitreNom.contains('mezzo')) {
      if (widget.vocalise.altoFiles != null && widget.vocalise.altoFiles!.isNotEmpty) {
        files.addAll(widget.vocalise.altoUrls);
      }
    } else if (pupitreNom.contains('ténor') || pupitreNom.contains('tenor')) {
      if (widget.vocalise.tenorFiles != null && widget.vocalise.tenorFiles!.isNotEmpty) {
        files.addAll(widget.vocalise.tenorUrls);
      }
    } else if (pupitreNom.contains('basse') || pupitreNom.contains('bariton')) {
      if (widget.vocalise.basseFiles != null && widget.vocalise.basseFiles!.isNotEmpty) {
        files.addAll(widget.vocalise.basseUrls);
      }
    } else if (pupitreNom.contains('tutti')) {
      if (widget.vocalise.tuttiFiles != null && widget.vocalise.tuttiFiles!.isNotEmpty) {
        files.addAll(widget.vocalise.tuttiUrls);
      }
    }

    // Si aucun fichier spécifique au pupitre, utiliser les fichiers audio généraux (fallback)
    if (files.isEmpty) {
      if (widget.vocalise.audioFiles != null && widget.vocalise.audioFiles!.isNotEmpty) {
        files.addAll(widget.vocalise.audioUrls);
      } else if (widget.vocalise.audioPath != null && widget.vocalise.audioUrl != null) {
        files.add(widget.vocalise.audioUrl!);
      }
    }

    return files;
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
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
          text: widget.vocalise.title,
          color: Colors.white,
          size: 18,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        actions: [
          if (_audioPlayerService.isPlaying)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: () => _audioPlayerService.pause(),
              tooltip: 'Arrêter la lecture',
            ),
        ],
      ),
      body: Column(
        children: [
          // En-tête de la vocalise
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
                        widget.vocalise.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.vocalise.description != null)
                        Text(
                          widget.vocalise.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          widget.vocalise.voicePart,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppConstance.primary.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // TabBar pour les pupitres
          TabBar(
            controller: _tabController!,
            isScrollable: true,
            labelColor: AppConstance.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppConstance.primary,
            tabs: [
              const Tab(text: 'Général', icon: Icon(Icons.folder, size: 16)),
              ..._pupitres.map((pupitre) => Tab(
                text: pupitre.nom,
                icon: Icon(
                  pupitre.icon != null ? _getIconFromString(pupitre.icon!) : Icons.person,
                  size: 16,
                ),
              )),
            ],
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                _buildGeneralTab(),
                ..._pupitres.map((pupitre) {
                  List<String> pupitreFiles = _getFilesForPupitre(pupitre.id);
                  Color pupitreColor = pupitre.color != null
                      ? Color(int.parse(pupitre.color!.replaceAll('#', '0xFF')))
                      : Colors.blue;
                  return _buildPupitreTab(pupitre.nom, pupitreFiles, pupitreColor);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'person':
      case 'person_outline':
        return Icons.person;
      case 'group':
      case 'groups':
        return Icons.group;
      case 'music_note':
      case 'music':
        return Icons.music_note;
      default:
        return Icons.person;
    }
  }

  Widget _buildGeneralTab() {
    // Collecter les fichiers PDF et images
    List<String> pdfFiles = [];
    List<String> imageFiles = [];

    if (widget.vocalise.pdfFiles != null && widget.vocalise.pdfFiles!.isNotEmpty) {
      pdfFiles.addAll(widget.vocalise.pdfUrls);
    }

    if (widget.vocalise.imageFiles != null && widget.vocalise.imageFiles!.isNotEmpty) {
      imageFiles.addAll(widget.vocalise.imageUrls);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fichiers PDF
          if (pdfFiles.isNotEmpty)
            _buildFileSection(
              title: 'Partitions PDF',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              files: pdfFiles,
            ),

          if (pdfFiles.isNotEmpty && imageFiles.isNotEmpty)
            const SizedBox(height: 16),

          // Fichiers Images
          if (imageFiles.isNotEmpty)
            _buildFileSection(
              title: 'Images',
              icon: Icons.image,
              color: Colors.blue,
              files: imageFiles,
            ),

          // Message si aucun fichier
          if (pdfFiles.isEmpty && imageFiles.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun fichier PDF ou image disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Informations de la vocalise
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
                  _buildInfoRow('Partie vocale', widget.vocalise.voicePart),
                  if (widget.vocalise.choraleName != null)
                    _buildInfoRow('Chorale', widget.vocalise.choraleName!),
                  _buildInfoRow('Créé le', _formatDate(widget.vocalise.createdAt)),
                  _buildInfoRow('Modifié le', _formatDate(widget.vocalise.updatedAt)),
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

  Widget _buildPupitreTab(String pupitreName, List<String> files, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                          '${files.length} fichier(s) audio disponible(s)',
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
          ),

          const SizedBox(height: 16),

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
    bool isAudio = _isAudioFile(file);
    bool isPdf = _isPdfFile(file);
    bool isImage = _isImageFile(file);
    final fileStatus = _fileStatuses[file] ?? FileDownloadStatus.notDownloaded;
    final isDownloading = _downloadingFiles[file] ?? false;

    // Icône selon l'état du fichier
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (isDownloading) {
      statusIcon = Icons.download;
      statusColor = Colors.orange;
      statusText = 'Téléchargement...';
    } else {
      switch (fileStatus) {
        case FileDownloadStatus.downloaded:
          statusIcon = Icons.check_circle;
          statusColor = Colors.green;
          statusText = 'Téléchargé';
          break;
        case FileDownloadStatus.outdated:
          statusIcon = Icons.update;
          statusColor = Colors.orange;
          statusText = 'Mise à jour disponible';
          break;
        case FileDownloadStatus.notDownloaded:
          statusIcon = Icons.download;
          statusColor = Colors.grey;
          statusText = 'Non téléchargé';
          break;
      }
    }

    // Obtenir le chemin local si le fichier est téléchargé
    Future<String?> getLocalPath() async {
      if (fileStatus == FileDownloadStatus.downloaded || fileStatus == FileDownloadStatus.outdated) {
        final isRemoteUrl = file.startsWith('http://') || file.startsWith('https://');
        String fileUrl = file;
        if (!isRemoteUrl && !file.startsWith('/')) {
          fileUrl = '${AppConstance.baseURL}/storage/$file';
        }
        return await LocalFileService.getLocalFilePath(fileUrl);
      }
      return null;
    }

    // Fonction pour ouvrir le fichier selon son type
    Future<void> openFile() async {
      if (isDownloading) {
        ToastService.info(context, 'Téléchargement en cours, veuillez patienter...');
        return;
      }

      try {
        final isRemoteUrl = file.startsWith('http://') || file.startsWith('https://');
        String fileUrl = file;

        if (!isRemoteUrl && !file.startsWith('/')) {
          fileUrl = '${AppConstance.baseURL}/storage/$file';
        } else if (!isRemoteUrl) {
          if (isAudio) {
            _playAudioLocal(file);
            return;
          } else if (isImage) {
            _viewImageLocal(file);
            return;
          } else if (isPdf) {
            _viewPdfLocal(file);
            return;
          }
        }

        String? localPath = await LocalFileService.getLocalFilePath(fileUrl);

        if (localPath == null) {
          setState(() {
            _downloadingFiles[file] = true;
          });

          localPath = await LocalFileService.downloadFile(fileUrl);

          setState(() {
            _downloadingFiles[file] = false;
          });

          if (localPath == null) {
            throw Exception('Impossible de télécharger le fichier');
          }

          final newStatus = await LocalFileService.getFileStatus(fileUrl);
          setState(() {
            _fileStatuses[file] = newStatus;
          });
        }

        final localFile = File(localPath);
        if (!await localFile.exists()) {
          throw Exception('Le fichier n\'existe pas: ${localPath.split('/').last}');
        }

        if (isAudio) {
          _playAudioLocal(localPath);
        } else if (isPdf) {
          _viewPdfLocal(localPath);
        } else if (isImage) {
          _viewImageLocal(localPath);
        }

      } catch (e) {
        print('❌ Erreur lors de l\'ouverture du fichier: $e');
        setState(() {
          _downloadingFiles[file] = false;
        });

        if (mounted) {
          ToastService.error(
            context,
            'Erreur: ${e.toString()}',
            duration: const Duration(seconds: 5),
          );
        }
      }
    }

    return InkWell(
      onTap: openFile,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (isImage && (fileStatus == FileDownloadStatus.downloaded || fileStatus == FileDownloadStatus.outdated))
              FutureBuilder<String?>(
                future: getLocalPath(),
                builder: (context, snapshot) {
                  final localPath = snapshot.data;
                  if (localPath != null) {
                    final localFile = File(localPath);
                    if (localFile.existsSync()) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          localFile,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image, color: color, size: 24);
                          },
                        ),
                      );
                    }
                  }
                  return Icon(Icons.image, color: color, size: 24);
                },
              )
            else
              Icon(
                isAudio ? Icons.audiotrack : (isPdf ? Icons.picture_as_pdf : Icons.image),
                color: color,
                size: 24,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.split('/').last,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        isAudio ? 'Fichier audio' : (isPdf ? 'Document PDF' : 'Image'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isDownloading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.open_in_new, color: Colors.grey.shade600, size: 20),
          ],
        ),
      ),
    );
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
            'Aucun fichier audio pour le pupitre $pupitreName',
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
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
            width: 120,
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
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  bool _isAudioFile(String file) {
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.opus', '.flac', '.mp4'];
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

  Future<void> _playAudioLocal(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Le fichier audio n\'existe pas: ${localPath.split('/').last}');
      }

      final fileName = localPath.split('/').last;
      await _audioPlayerService.playAudio(localPath, title: fileName);

      print('✅ Audio en cours de lecture: $fileName');
    } catch (e) {
      print('❌ Erreur lors de la lecture audio: $e');
      if (mounted) {
        ToastService.error(
          context,
          'Erreur lors de la lecture: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _viewPdfLocal(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Le fichier PDF n\'existe pas: ${localPath.split('/').last}');
      }

      if (mounted) {
        await PdfService.showPdfOptions(localPath, context);
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture du PDF: $e');
      if (mounted) {
        ToastService.error(
          context,
          'Erreur lors de l\'ouverture du PDF: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _viewImageLocal(String localPath) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Le fichier image n\'existe pas: ${localPath.split('/').last}');
      }

      final imageName = localPath.split('/').last;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageViewerScreen(
              imagePath: localPath,
              imageName: imageName,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ouverture de l\'image: $e');
      if (mounted) {
        ToastService.error(
          context,
          'Erreur lors de l\'ouverture de l\'image: ${e.toString()}',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}

/// Écran de visionneuse d'images avec zoom
class ImageViewerScreen extends StatelessWidget {
  final String imagePath;
  final String imageName;

  const ImageViewerScreen({
    super.key,
    required this.imagePath,
    required this.imageName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          imageName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          panEnabled: true,
          scaleEnabled: true,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white70, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Impossible de charger l\'image',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
