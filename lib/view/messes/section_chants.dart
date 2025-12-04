import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/messe_section.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/models/chorale_pupitre.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/messe_service.dart';
import 'package:voxbox/services/chorale_service.dart';
import 'package:voxbox/services/audio_service.dart';
import 'package:voxbox/services/pdf_service.dart';
import 'package:voxbox/services/local_file_service.dart';
import 'package:voxbox/view/messes/chant_details.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class SectionChantsScreen extends StatefulWidget {
  final MesseSection section;

  const SectionChantsScreen({
    super.key,
    required this.section,
  });

  @override
  State<SectionChantsScreen> createState() => _SectionChantsScreenState();
}

class _SectionChantsScreenState extends State<SectionChantsScreen> with SingleTickerProviderStateMixin {
  List<ChantDeMesse> chants = [];
  bool loading = false;
  bool syncing = false;
  List<ChoralePupitre> _pupitres = [];
  TabController? _tabController;
  int? _choraleId;
  Map<String, FileDownloadStatus> _fileStatuses = {};
  Map<String, bool> _downloadingFiles = {};

  @override
  void initState() {
    super.initState();
    _loadChants();
    _loadPupitres();
    _checkFilesStatus();
  }

  Future<void> _checkFilesStatus() async {
    // Vérifier le statut de tous les fichiers
    final allFiles = <String>[];
    for (var chant in chants) {
      if (chant.pdfFiles != null) allFiles.addAll(chant.pdfUrls);
      if (chant.imageFiles != null) allFiles.addAll(chant.imageUrls);
      if (chant.audioFiles != null) allFiles.addAll(chant.audioUrls);
    }
    
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

  Future<void> _loadChants() async {
    setState(() {
      loading = true;
    });

    try {
      print('🔄 Chargement des chants pour la section ID: ${widget.section.id} (${widget.section.nom})');
      
      // D'abord charger depuis le cache local (avec fichiers ajoutés)
      final cachedChants = await MesseService.getSectionChantsFromCache(widget.section.id);
      if (cachedChants.isNotEmpty) {
        print('📦 ${cachedChants.length} chant(s) chargé(s) depuis le cache local');
        setState(() {
          chants = cachedChants;
          loading = false;
        });
      }

      // Ensuite essayer de synchroniser avec le serveur
      var response = await MesseService.getSectionChants(widget.section.id);
      if (response.error == null && response.data != null) {
        final loadedChants = response.data as List<ChantDeMesse>;
        print('✅ ${loadedChants.length} chant(s) chargé(s) depuis le serveur');
        
        // Afficher les détails de chaque chant
        for (var chant in loadedChants) {
          print('   - ${chant.titre}');
          print('     Audio: ${chant.audioFiles?.length ?? 0} fichiers');
          print('     PDF: ${chant.pdfFiles?.length ?? 0} fichiers');
          print('     Images: ${chant.imageFiles?.length ?? 0} fichiers');
        }
        
        setState(() {
          chants = loadedChants;
          loading = false;
        });
      } else {
        print('❌ Erreur lors du chargement: ${response.error}');
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
      print('💥 Exception lors du chargement des chants: $e');
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

  // Organiser les fichiers par type et pupitre
  Map<String, List<String>> _organizeFilesByType() {
    Map<String, List<String>> organized = {
      'general': [], // Fichiers non-audio (PDF, images)
    };
    
    for (var chant in chants) {
      // Fichiers PDF dans Général
      if (chant.pdfFiles != null) {
        organized['general']!.addAll(chant.pdfUrls);
      }
      if (chant.pdfPath != null) {
        organized['general']!.add(chant.pdfUrl!);
      }
      
      // Fichiers images dans Général
      if (chant.imageFiles != null) {
        organized['general']!.addAll(chant.imageUrls);
      }
      if (chant.imagePath != null) {
        organized['general']!.add(chant.imageUrl!);
      }
      
      // Fichiers audio seront organisés par pupitre (pour l'instant dans général)
      if (chant.audioFiles != null) {
        organized['general']!.addAll(chant.audioUrls);
      }
      if (chant.audioPath != null) {
        organized['general']!.add(chant.audioUrl!);
      }
    }
    
    return organized;
  }

  List<String> _getFilesForPupitre(int pupitreId) {
    // Pour l'instant, retourner les fichiers audio de tous les chants
    // TODO: Filtrer par pupitre_id quand les données seront disponibles
    List<String> files = [];
    for (var chant in chants) {
      if (chant.audioFiles != null) {
        files.addAll(chant.audioUrls);
      }
      if (chant.audioPath != null) {
        files.add(chant.audioUrl!);
      }
    }
    return files;
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return Scaffold(
        appBar: AppBar(
          title: MyText(
            text: widget.section.nom,
            color: Colors.white,
            size: 20,
            fontweight: FontWeight.bold,
          ),
          backgroundColor: AppConstance.primary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final organizedFiles = _organizeFilesByType();

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
          if (AudioService.isPlaying)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: () => AudioService.stopAudio(),
              tooltip: 'Arrêter la lecture',
            ),
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
                        'Aucune partition trouvée',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
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
                          _buildGeneralTab(organizedFiles['general'] ?? []),
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

  Widget _buildGeneralTab(List<String> files) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fichiers PDF
          if (chants.any((c) => c.pdfFiles?.isNotEmpty == true || c.pdfPath != null))
            _buildFileSection(
              title: 'Partitions PDF',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              files: chants.expand<String>((c) => c.pdfFiles != null ? c.pdfUrls : (c.pdfPath != null ? [c.pdfUrl!] : <String>[])).toList(),
            ),
          
          const SizedBox(height: 16),
          
          // Fichiers Images
          if (chants.any((c) => c.imageFiles?.isNotEmpty == true || c.imagePath != null))
            _buildFileSection(
              title: 'Images',
              icon: Icons.image,
              color: Colors.blue,
              files: chants.expand<String>((c) => c.imageFiles != null ? c.imageUrls : (c.imagePath != null ? [c.imageUrl!] : <String>[])).toList(),
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
                    color: color.withOpacity(0.1),
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
        default:
          statusIcon = Icons.download;
          statusColor = Colors.grey;
          statusText = 'Non téléchargé';
          break;
      }
    }
    
    // Fonction pour ouvrir le fichier selon son type
    Future<void> openFile() async {
      // Vérifier si le fichier est en cours de téléchargement
      if (isDownloading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléchargement en cours, veuillez patienter...'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        String? localPath;

        // ÉTAPE 1: Vérifier si le fichier est déjà disponible localement
        print('🔍 Recherche du fichier: $file');
        localPath = await LocalFileService.getLocalFilePath(file);

        // ÉTAPE 2: Si pas trouvé ou obsolète, télécharger
        if (localPath == null || fileStatus == FileDownloadStatus.outdated) {
          print('📥 Téléchargement nécessaire pour: $file');

          setState(() {
            _downloadingFiles[file] = true;
          });

          localPath = await LocalFileService.downloadFile(
            file,
            forceRedownload: fileStatus == FileDownloadStatus.outdated,
          );

          setState(() {
            _downloadingFiles[file] = false;
          });

          if (localPath == null) {
            throw Exception('Impossible de télécharger ou de trouver le fichier');
          }

          // Mettre à jour le statut
          final newStatus = await LocalFileService.getFileStatus(file);
          setState(() {
            _fileStatuses[file] = newStatus;
          });

          print('✅ Fichier disponible: $localPath');
        } else {
          print('✅ Fichier déjà disponible: $localPath');
        }

        // ÉTAPE 3: Vérifier que le fichier existe vraiment avant de l'ouvrir
        final fileExists = await File(localPath).exists();
        if (!fileExists) {
          throw Exception('Le fichier n\'existe pas: $localPath');
        }

        // ÉTAPE 4: Ouvrir le fichier selon son type
        print('📂 Ouverture du fichier: $localPath');
        if (isAudio) {
          _playAudio(localPath);
        } else if (isPdf) {
          _viewPdf(localPath);
        } else if (isImage) {
          _viewImage(localPath);
        }

      } catch (e) {
        print('❌ Erreur lors de l\'ouverture du fichier: $e');
        setState(() {
          _downloadingFiles[file] = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
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
                      Icon(
                        statusIcon,
                        size: 14,
                        color: statusColor,
                      ),
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                Icons.open_in_new,
                color: Colors.grey.shade600,
                size: 20,
              ),
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
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
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

  void _playAudio(String filePath) async {
    try {
      // Si c'est un chemin local, utiliser directement
      if (filePath.startsWith('/')) {
        await AudioService.playAudio(filePath);
      } else {
        // Sinon, c'est une URL, télécharger d'abord
        final localPath = await LocalFileService.downloadFile(filePath);
        if (localPath != null) {
          await AudioService.playAudio(localPath);
        } else {
          throw Exception('Impossible de télécharger le fichier');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lecture en cours: ${filePath.split('/').last}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la lecture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewPdf(String filePath) async {
    try {
      // Si c'est un chemin local, utiliser directement
      if (filePath.startsWith('/')) {
        await PdfService.showPdfOptions(filePath, context);
      } else {
        // Sinon, c'est une URL, télécharger d'abord
        final localPath = await LocalFileService.downloadFile(filePath);
        if (localPath != null) {
          await PdfService.showPdfOptions(localPath, context);
        } else {
          throw Exception('Impossible de télécharger le fichier');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture du PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewImage(String filePath) async {
    try {
      // Si c'est un chemin local, utiliser directement
      if (filePath.startsWith('/')) {
        final file = File(filePath);
        if (await file.exists()) {
          final uri = Uri.file(filePath);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      } else {
        // Sinon, c'est une URL, télécharger d'abord
        final localPath = await LocalFileService.downloadFile(filePath);
        if (localPath != null) {
          final file = File(localPath);
          if (await file.exists()) {
            final uri = Uri.file(localPath);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        } else {
          throw Exception('Impossible de télécharger le fichier');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
