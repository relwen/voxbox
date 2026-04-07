import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/models/chorale_pupitre.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/view/messes/add_files_to_chant.dart';
import 'package:voxbox/services/chant_service.dart';
import 'package:voxbox/services/chorale_service.dart';
import 'package:voxbox/services/auth_service.dart';
import 'package:voxbox/services/file_upload_service.dart';
import 'package:voxbox/services/audio_service.dart';
import 'package:voxbox/services/pdf_service.dart';
import 'package:voxbox/services/local_file_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChantDetailsScreen extends StatefulWidget {
  final ChantDeMesse chant;

  const ChantDetailsScreen({super.key, required this.chant});

  @override
  State<ChantDetailsScreen> createState() => _ChantDetailsScreenState();
}

class _ChantDetailsScreenState extends State<ChantDetailsScreen> with SingleTickerProviderStateMixin {
  bool loading = false;
  TabController? _tabController;
  ChantDeMesse? _currentChant;
  List<ChoralePupitre> _pupitres = [];
  int? _choraleId;
  Map<String, FileDownloadStatus> _fileStatuses = {};
  Map<String, bool> _downloadingFiles = {};

  @override
  void initState() {
    super.initState();
    _currentChant = widget.chant;
    // Créer un TabController temporaire avec 1 onglet (Général) en attendant le chargement des pupitres
    _tabController = TabController(length: 1, vsync: this);
    _loadChantData();
    _loadPupitres();
    _checkFilesStatus();
  }

  Future<void> _checkFilesStatus() async {
    if (_currentChant == null) return;
    
    // Vérifier le statut de tous les fichiers
    final allFiles = <String>[];
    if (_currentChant!.pdfFiles != null) allFiles.addAll(_currentChant!.pdfUrls);
    if (_currentChant!.imageFiles != null) allFiles.addAll(_currentChant!.imageUrls);
    if (_currentChant!.audioFiles != null) allFiles.addAll(_currentChant!.audioUrls);
    
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
      print('🔄 Chargement des pupitres...');
      // Récupérer le choraleId depuis l'utilisateur
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userString = prefs.getString('user');
      if (userString != null) {
        Map<String, dynamic> userMap = jsonDecode(userString);
        User user = User.fromJson(userMap);
        _choraleId = user.choraleId;
        
        print('📋 Chorale ID: $_choraleId');
        
        if (_choraleId != null) {
          final response = await ChoraleService.getPupitres(_choraleId!);
          print('📡 Réponse API pupitres: ${response.error ?? "Succès"}');
          
          if (response.error == null && response.data != null) {
            final pupitres = response.data as List<ChoralePupitre>;
            print('✅ ${pupitres.length} pupitres chargés: ${pupitres.map((p) => p.nom).join(", ")}');
            
            setState(() {
              _pupitres = pupitres;
              // Créer le TabController avec le nombre de pupitres + 1 (pour Général)
              _tabController?.dispose();
              _tabController = TabController(length: _pupitres.length + 1, vsync: this);
              print('✅ TabController créé avec ${_pupitres.length + 1} onglets');
            });
          } else {
            print('❌ Erreur lors du chargement des pupitres: ${response.error}');
            // En cas d'erreur, utiliser un TabController avec seulement Général
            setState(() {
              _pupitres = [];
              _tabController?.dispose();
              _tabController = TabController(length: 1, vsync: this);
            });
          }
        } else {
          print('⚠️ Chorale ID est null');
          setState(() {
            _pupitres = [];
            _tabController?.dispose();
            _tabController = TabController(length: 1, vsync: this);
          });
        }
      } else {
        print('⚠️ Aucun utilisateur trouvé dans SharedPreferences');
        setState(() {
          _pupitres = [];
          _tabController?.dispose();
          _tabController = TabController(length: 1, vsync: this);
        });
      }
    } catch (e) {
      print('💥 Exception lors du chargement des pupitres: $e');
      // En cas d'erreur, utiliser un TabController avec seulement Général
      setState(() {
        _pupitres = [];
        _tabController?.dispose();
        _tabController = TabController(length: 1, vsync: this);
      });
    }
  }

  Future<void> _loadChantData() async {
    setState(() {
      loading = true;
    });

    try {
      print('🔄 Chargement des données du chant ID: ${widget.chant.id}');
      
      // D'abord charger les données locales (avec fichiers en attente)
      final localChant = await ChantService.getLocalChant(widget.chant.id);
      if (localChant != null) {
        print('📦 Chant chargé depuis le cache local');
        print('   - PDF: ${localChant.pdfFiles?.length ?? 0} fichiers');
        print('   - Images: ${localChant.imageFiles?.length ?? 0} fichiers');
        print('   - Audio: ${localChant.audioFiles?.length ?? 0} fichiers');
        setState(() {
          _currentChant = localChant;
        });
      }

      // Ensuite essayer de synchroniser avec le serveur
      // Récupérer les chants de la section et trouver celui qui correspond
      if (widget.chant.sectionId > 0) {
        final response = await ChantService.getSectionChants(widget.chant.sectionId);
      if (response.error == null && response.data != null) {
          final chants = response.data as List<ChantDeMesse>;
          final chant = chants.firstWhere(
            (c) => c.id == widget.chant.id,
            orElse: () => widget.chant,
          );
        print('✅ Chant synchronisé depuis le serveur');
        print('   - PDF: ${chant.pdfFiles?.length ?? 0} fichiers');
        print('   - Images: ${chant.imageFiles?.length ?? 0} fichiers');
        print('   - Audio: ${chant.audioFiles?.length ?? 0} fichiers');
        print('   - Soprano: ${chant.sopranoFiles?.length ?? 0} fichiers');
        print('   - Alto: ${chant.altoFiles?.length ?? 0} fichiers');
        print('   - Ténor: ${chant.tenorFiles?.length ?? 0} fichiers');
        print('   - Basse: ${chant.basseFiles?.length ?? 0} fichiers');
        print('   - Tutti: ${chant.tuttiFiles?.length ?? 0} fichiers');
        setState(() {
          _currentChant = chant;
        });
        // Vérifier les statuts des fichiers après le chargement
        _checkFilesStatus();
      } else {
        print('❌ Erreur lors de la synchronisation: ${response.error}');
        }
      } else {
        print('⚠️ Section ID non disponible, impossible de synchroniser');
      }
    } catch (e) {
      print('💥 Exception lors du chargement des données du chant: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentChant == null || _tabController == null) {
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
          // Contrôle audio
          if (AudioService.isPlaying)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: () => AudioService.stopAudio(),
              tooltip: 'Arrêter la lecture',
            ),
          // Indicateur de synchronisation
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
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _showDownloads(),
            tooltip: 'Voir les téléchargements',
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
          
          // TabBar pour les pupitres (dynamique)
          if (_tabController != null)
          TabBar(
            controller: _tabController!,
            isScrollable: true,
            labelColor: AppConstance.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppConstance.primary,
            tabs: [
              const Tab(text: 'Général', icon: Icon(Icons.folder, size: 16)),
              ..._pupitres.map((pupitre) {
                print('📌 Création du tab pour pupitre: ${pupitre.nom} (ID: ${pupitre.id})');
                return Tab(
                  text: pupitre.nom,
                  icon: Icon(
                    pupitre.icon != null ? _getIconFromString(pupitre.icon!) : Icons.person,
                    size: 16,
                  ),
                );
              }),
            ],
          ),
          
          // Contenu des onglets
          if (_tabController != null)
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                _buildGeneralTab(),
                ..._pupitres.map((pupitre) {
                  // Récupérer les fichiers audio pour ce pupitre
                  List<String> pupitreFiles = _getFilesForPupitre(pupitre.id);
                  Color pupitreColor = pupitre.color != null 
                      ? Color(int.parse(pupitre.color!.replaceAll('#', '0xFF')))
                      : Colors.blue;
                  print('🎵 Fichiers pour pupitre ${pupitre.nom}: ${pupitreFiles.length} fichiers');
                  return _buildPupitreTab(pupitre.nom, pupitreFiles, pupitreColor, pupitre.id);
                }),
              ],
            ),
            )
          else
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
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

  List<String> _getFilesForPupitre(int pupitreId) {
    // Récupérer les fichiers audio pour ce pupitre spécifique
    List<String> files = [];
    
    if (_currentChant != null) {
      print('🎵 Recherche de fichiers audio pour pupitre ID: $pupitreId');
      
      // Mapper les anciens champs par pupitre (temporaire jusqu'à ce que les données soient structurées par pupitre_id)
      // On essaie de mapper par nom de pupitre ou par position
      String? pupitreNom;
      if (_pupitres.isNotEmpty) {
        try {
          final pupitre = _pupitres.firstWhere((p) => p.id == pupitreId);
          pupitreNom = pupitre.nom.toLowerCase();
          print('📌 Nom du pupitre trouvé: ${pupitre.nom}');
        } catch (e) {
          print('⚠️ Pupitre avec ID $pupitreId non trouvé');
        }
      }
      
      // Mapper par nom de pupitre
      if (pupitreNom != null) {
        if (pupitreNom.contains('soprano')) {
          if (_currentChant!.sopranoFiles != null && _currentChant!.sopranoFiles!.isNotEmpty) {
            files.addAll(_currentChant!.sopranoUrls);
          }
        } else if (pupitreNom.contains('alto')) {
          if (_currentChant!.altoFiles != null && _currentChant!.altoFiles!.isNotEmpty) {
            files.addAll(_currentChant!.altoUrls);
          }
        } else if (pupitreNom.contains('ténor') || pupitreNom.contains('tenor')) {
          if (_currentChant!.tenorFiles != null && _currentChant!.tenorFiles!.isNotEmpty) {
            files.addAll(_currentChant!.tenorUrls);
          }
        } else if (pupitreNom.contains('basse')) {
          if (_currentChant!.basseFiles != null && _currentChant!.basseFiles!.isNotEmpty) {
            files.addAll(_currentChant!.basseUrls);
          }
        } else if (pupitreNom.contains('tutti')) {
          if (_currentChant!.tuttiFiles != null && _currentChant!.tuttiFiles!.isNotEmpty) {
            files.addAll(_currentChant!.tuttiUrls);
          }
        }
      }
      
      // Si aucun fichier spécifique au pupitre, utiliser les fichiers audio généraux
      if (files.isEmpty) {
        print('📢 Aucun fichier spécifique trouvé, utilisation des fichiers audio généraux');
        // Fichiers audio multiples
        if (_currentChant!.audioFiles != null && _currentChant!.audioFiles!.isNotEmpty) {
          files.addAll(_currentChant!.audioUrls);
        }
        // Fichier audio unique
        if (_currentChant!.audioPath != null) {
          files.add(_currentChant!.audioUrl!);
        }
      }
      
      print('✅ ${files.length} fichier(s) audio trouvé(s) pour pupitre $pupitreId');
    }
    
    return files;
  }

  Widget _buildPupitreTab(String pupitreName, List<String> files, Color color, [int? pupitreId]) {
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
        } else if (isPending) {
          statusIcon = Icons.cloud_upload;
          statusColor = Colors.orange;
          statusText = 'En attente de synchronisation';
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
              border: Border.all(
                color: isPending ? Colors.orange : Colors.grey.shade300,
                width: isPending ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isPending ? Colors.orange.withOpacity(0.1) : null,
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Icon(
                      _getFileIcon(file),
                      color: color,
                      size: 24,
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
                          Expanded(
                            child: Text(
                              file.split('/').last,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            isAudio ? 'Fichier audio' : (isPdf ? 'Document PDF' : (isImage ? 'Image' : 'Fichier')),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
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
    // Récupérer UNIQUEMENT les fichiers non-audio (PDF et images)
    // Les fichiers audio doivent être dans les onglets pupitre
    List<String> pdfFiles = [];
    List<String> imageFiles = [];

    if (_currentChant != null) {
      // Fichiers PDF (NON-AUDIO, donc dans Général)
      if (_currentChant!.pdfFiles != null && _currentChant!.pdfFiles!.isNotEmpty) {
        pdfFiles.addAll(_currentChant!.pdfUrls);
      }
      if (_currentChant!.pdfPath != null) {
        pdfFiles.add(_currentChant!.pdfUrl!);
      }

      // Fichiers Images (NON-AUDIO, donc dans Général)
      if (_currentChant!.imageFiles != null && _currentChant!.imageFiles!.isNotEmpty) {
        imageFiles.addAll(_currentChant!.imageUrls);
      }
      if (_currentChant!.imagePath != null) {
        imageFiles.add(_currentChant!.imageUrl!);
      }

      // NE PAS INCLURE les fichiers audio ici !
      // Ils seront affichés dans les onglets pupitres
    }

    print('📄 Fichiers PDF dans Général: ${pdfFiles.length}');
    print('🖼️ Fichiers Images dans Général: ${imageFiles.length}');
    print('🎵 Fichiers Audio exclus de Général (affichés dans les pupitres)');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fichiers PDF (non-audio, donc dans Général)
          if (pdfFiles.isNotEmpty)
            _buildFileSection(
              title: 'Partitions PDF',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              files: pdfFiles,
            ),

          if (pdfFiles.isNotEmpty && imageFiles.isNotEmpty)
            const SizedBox(height: 16),

          // Fichiers Images (non-audio, donc dans Général)
          if (imageFiles.isNotEmpty)
            _buildFileSection(
              title: 'Images',
              icon: Icons.image,
              color: Colors.blue,
              files: imageFiles,
            ),
          
          // Message si aucun fichier non-audio
          if (pdfFiles.isEmpty && imageFiles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun fichier non-audio',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les fichiers PDF et images apparaîtront ici',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
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
      
      // Si c'est un fichier local, le copier vers le dossier de téléchargements
      if (file.startsWith('/')) {
        final localFile = File(file);
        if (await localFile.exists()) {
          final directory = await getApplicationDocumentsDirectory();
          final downloadDir = Directory('${directory.path}/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          
          final destinationFile = File('${downloadDir.path}/$fileName');
          await localFile.copy(destinationFile.path);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fichier copié vers: ${destinationFile.path}'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Ouvrir',
                  onPressed: () {
                    if (_isImageFile(destinationFile.path)) {
                      _viewImage(destinationFile.path);
                    } else {
                      _viewPdf(destinationFile.path);
                    }
                  },
                ),
              ),
            );
          }
        } else {
          throw Exception('Fichier local introuvable');
        }
      } else {
        // Si c'est une URL, utiliser le service de téléchargement
        final success = await ChantService.downloadFile(file, fileName);
        
        if (success) {
          // Construire le chemin du fichier téléchargé
          final directory = await getApplicationDocumentsDirectory();
          final downloadDir = Directory('${directory.path}/Downloads');
          final downloadedFile = File('${downloadDir.path}/$fileName');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fichier téléchargé vers: ${downloadedFile.path}'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Ouvrir',
                  onPressed: () {
                    if (_isImageFile(downloadedFile.path)) {
                      _viewImage(downloadedFile.path);
                    } else {
                      _viewPdf(downloadedFile.path);
                    }
                  },
                ),
              ),
            );
          }
        } else {
          throw Exception('Échec du téléchargement');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _playAudio(String filePath) async {
    try {
      setState(() {
        loading = true;
      });

      // Si c'est un chemin local, utiliser directement
      String audioPath = filePath;
      if (!filePath.startsWith('/')) {
        // Sinon, c'est une URL, vérifier si téléchargé
        final localPath = await LocalFileService.getLocalFilePath(filePath);
        if (localPath != null) {
          audioPath = localPath;
        } else {
          // Télécharger d'abord
          final downloadedPath = await LocalFileService.downloadFile(filePath);
          if (downloadedPath != null) {
            audioPath = downloadedPath;
          } else {
            throw Exception('Impossible de télécharger le fichier audio');
          }
        }
      }

      // Utiliser le service audio pour la lecture
      await AudioService.playAudio(audioPath, onComplete: () {
        if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lecture terminée'),
        backgroundColor: Colors.green,
      ),
    );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lecture en cours: ${audioPath.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Arrêter',
              onPressed: () => AudioService.stopAudio(),
            ),
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
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _viewPdf(String filePath) async {
    String? pdfPath;
    try {
      setState(() {
        loading = true;
      });

      // Si c'est un chemin local, utiliser directement
      pdfPath = filePath;
      if (!filePath.startsWith('/')) {
        // Sinon, c'est une URL, vérifier si téléchargé
        final localPath = await LocalFileService.getLocalFilePath(filePath);
        if (localPath != null) {
          pdfPath = localPath;
        } else {
          // Télécharger d'abord
          final downloadedPath = await LocalFileService.downloadFile(filePath);
          if (downloadedPath != null) {
            pdfPath = downloadedPath;
          } else {
            throw Exception('Impossible de télécharger le fichier PDF');
          }
        }
      }

      print('Tentative d\'ouverture du PDF: $pdfPath');

      // Vérifier si le PDF est valide
      final isValid = await PdfService.isValidPdf(pdfPath!);
      if (!isValid) {
        throw Exception('Fichier PDF invalide ou corrompu');
      }

      // Utiliser le nouveau service PDF avec options multiples
      await PdfService.showPdfOptions(pdfPath, context);
      
    } catch (e) {
      print('Erreur lors de l\'ouverture du PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture du PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Options',
              onPressed: () => _showPdfErrorOptions(pdfPath ?? filePath),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  /// Affiche des options supplémentaires en cas d'erreur
  void _showPdfErrorOptions(String file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Options PDF'),
        content: const Text('Le PDF n\'a pas pu être ouvert. Que souhaitez-vous faire ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadFile(file);
            },
            child: const Text('Télécharger'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyPdfToDownloads(file);
            },
            child: const Text('Copier vers téléchargements'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  /// Copie le PDF vers le dossier de téléchargements
  void _copyPdfToDownloads(String file) async {
    try {
      setState(() {
        loading = true;
      });

      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/Downloads');
      
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      
      final fileName = file.split('/').last;
      final destinationFile = File('${downloadDir.path}/$fileName');
      
      if (file.startsWith('/')) {
        // Fichier local
        final sourceFile = File(file);
        if (await sourceFile.exists()) {
          await sourceFile.copy(destinationFile.path);
          } else {
          throw Exception('Fichier source introuvable');
          }
        } else {
        // URL - télécharger
        final response = await http.get(Uri.parse(file));
        if (response.statusCode == 200) {
          await destinationFile.writeAsBytes(response.bodyBytes);
      } else {
          throw Exception('Erreur de téléchargement: ${response.statusCode}');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF copié vers: ${destinationFile.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ouvrir',
              onPressed: () => PdfService.openPdf(destinationFile.path, context),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la copie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void _viewImage(String filePath) async {
    try {
      setState(() {
        loading = true;
      });

      // Si c'est un chemin local, utiliser directement
      String imagePath = filePath;
      if (!filePath.startsWith('/')) {
        // Sinon, c'est une URL, vérifier si téléchargé
        final localPath = await LocalFileService.getLocalFilePath(filePath);
        if (localPath != null) {
          imagePath = localPath;
        } else {
          // Télécharger d'abord
          final downloadedPath = await LocalFileService.downloadFile(filePath);
          if (downloadedPath != null) {
            imagePath = downloadedPath;
          } else {
            throw Exception('Impossible de télécharger le fichier image');
          }
        }
      }

      print('Tentative d\'ouverture de l\'image: $imagePath');

      final localFile = File(imagePath);
      if (await localFile.exists()) {
        print('Fichier image local trouvé: ${localFile.path}');
        // Ouvrir le fichier local avec l'application par défaut
        final uri = Uri.file(imagePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          print('Image ouverte avec succès');
        } else {
          throw Exception('Impossible d\'ouvrir le fichier image avec l\'application par défaut');
        }
      } else {
        throw Exception('Fichier image introuvable: $imagePath');
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture de l\'image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture de l\'image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Télécharger',
              onPressed: () => _downloadFile(filePath),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
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
          await _loadChantData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${selectedFiles.length} fichier(s) ajouté(s) localement pour $pupitreName'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
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

  void _showDownloads() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/Downloads');
      
      if (!await downloadDir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun fichier téléchargé'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final files = await downloadDir.list().toList();
      final fileList = files.where((file) => file is File).cast<File>().toList();

      if (fileList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun fichier téléchargé'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fichiers Téléchargés'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: fileList.length,
                itemBuilder: (context, index) {
                  final file = fileList[index];
                  final fileName = file.path.split('/').last;
                  final isImage = _isImageFile(fileName);
                  
                  return ListTile(
                    leading: Icon(
                      isImage ? Icons.image : Icons.picture_as_pdf,
                      color: isImage ? Colors.blue : Colors.red,
                    ),
                    title: Text(fileName),
                    subtitle: Text('${(file.lengthSync() / 1024).toStringAsFixed(1)} KB'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () {
                            Navigator.pop(context);
                            if (isImage) {
                              _viewImage(file.path);
                            } else {
                              _viewPdf(file.path);
                            }
                          },
                          tooltip: 'Ouvrir',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await file.delete();
                            Navigator.pop(context);
                            _showDownloads(); // Rafraîchir la liste
                          },
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'affichage des téléchargements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
