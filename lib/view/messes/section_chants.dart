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
import 'package:voxbox/services/global_audio_player_service.dart';
import 'package:voxbox/services/pdf_service.dart';
import 'package:voxbox/services/local_file_service.dart';
import 'package:voxbox/services/unified_cache_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/view/messes/add_files_to_messe_section_screen.dart';
import 'package:voxbox/widgets/offline_indicator.dart';
import 'package:voxbox/widgets/shimmer_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  final GlobalAudioPlayerService _audioPlayerService = GlobalAudioPlayerService();

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
        } else {
          // Si choraleId est null, initialiser au moins un tab (Général)
          setState(() {
            _pupitres = [];
            _tabController?.dispose();
            _tabController = TabController(length: 1, vsync: this);
          });
        }
      } else {
        // Si utilisateur non connecté, initialiser au moins un tab
        setState(() {
          _pupitres = [];
          _tabController?.dispose();
          _tabController = TabController(length: 1, vsync: this);
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des pupitres: $e');
      if (mounted) {
        setState(() {
          _pupitres = [];
          _tabController?.dispose();
          _tabController = TabController(length: 1, vsync: this);
        });
      }
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
      
      // Utiliser messeId (ID réel de la RubriqueSection) pour récupérer les partitions
      final messeId = widget.section.messeId;
      print('📋 Section ID: ${widget.section.id}, Messe ID (RubriqueSection): $messeId');
      
      // PRIORITÉ 1: Utiliser les chants déjà chargés dans la section (depuis les références)
      if (widget.section.chants != null && widget.section.chants!.isNotEmpty) {
        print('📦 ${widget.section.chants!.length} chant(s) déjà chargé(s) dans la section');
        setState(() {
          chants = widget.section.chants!;
          loading = false;
        });
        
        // Sauvegarder dans le cache
        print('💾 Sauvegarde/Mise à jour des ${widget.section.chants!.length} chant(s) dans le cache unifié');
        await UnifiedCacheService.saveOrUpdateChants(widget.section.chants!);
        return;
      }
      
      // PRIORITÉ 2: Charger depuis le cache local (avec fichiers ajoutés)
      // IMPORTANT: Utiliser widget.section.id (sectionId) pour filtrer, pas messeId
      // Car chaque section a son propre ID unique, même si elles partagent le même messeId
      final cachedChants = await MesseService.getSectionChantsFromCache(widget.section.id, messeId: messeId);
      if (cachedChants.isNotEmpty) {
        print('📦 ${cachedChants.length} chant(s) trouvé(s) dans le cache pour la section ${widget.section.id} (${widget.section.nom})');
        // Vérifier que tous les chants appartiennent bien à cette section
        final validChants = cachedChants.where((chant) => chant.sectionId == widget.section.id).toList();
        if (validChants.length != cachedChants.length) {
          print('⚠️ ${cachedChants.length - validChants.length} chant(s) filtré(s) car ils n\'appartiennent pas à la section ${widget.section.id}');
          // Afficher les sectionId incorrects pour debug
          final incorrectSectionIds = cachedChants
              .where((chant) => chant.sectionId != widget.section.id)
              .map((c) => c.sectionId)
              .toSet();
          print('   SectionId incorrects trouvés: ${incorrectSectionIds.join(", ")}');
        }
        print('✅ ${validChants.length} chant(s) valide(s) pour la section ${widget.section.id} (${widget.section.nom})');
        setState(() {
          chants = validChants;
          loading = false;
        });
      }

      // PRIORITÉ 3: Synchroniser avec le serveur
      // Utiliser messeId (ID réel de la RubriqueSection) pour récupérer depuis le serveur
      // Passer aussi le nom de la section pour filtrer par messe_part et éviter le mélange entre messes
      // Mais les chants retournés doivent avoir le bon sectionId (widget.section.id)
      var response = await MesseService.getSectionChants(
        widget.section.id,
        messeId: messeId,
        sectionName: widget.section.nom, // Filtrer par nom de section pour distinguer les messes
      );
      if (response.error == null && response.data != null) {
        final loadedChants = response.data as List<ChantDeMesse>;
        print('✅ ${loadedChants.length} chant(s) chargé(s) depuis le serveur pour la section ${widget.section.id} (${widget.section.nom})');
        
        // Vérifier et corriger le sectionId de chaque chant
        final validChants = <ChantDeMesse>[];
        for (var chant in loadedChants) {
          if (chant.sectionId != widget.section.id) {
            print('⚠️ Correction sectionId pour chant ${chant.id}: ${chant.sectionId} -> ${widget.section.id}');
            validChants.add(chant.copyWith(sectionId: widget.section.id));
          } else {
            validChants.add(chant);
          }
        }
        
        // Afficher les détails de chaque chant
        for (var chant in validChants) {
          print('   - ${chant.titre} (sectionId: ${chant.sectionId})');
          print('     Audio: ${chant.audioFiles?.length ?? 0} fichiers');
          print('     PDF: ${chant.pdfFiles?.length ?? 0} fichiers');
          print('     Images: ${chant.imageFiles?.length ?? 0} fichiers');
        }
        
        // Afficher un résumé des fichiers trouvés
        int totalAudioFiles = 0;
        int totalPdfFiles = 0;
        int totalImageFiles = 0;
        Map<String, int> pupitreCounts = {};
        
        for (var chant in validChants) {
          totalAudioFiles += chant.audioFiles?.length ?? (chant.audioPath != null ? 1 : 0);
          totalPdfFiles += chant.pdfFiles?.length ?? (chant.pdfPath != null ? 1 : 0);
          totalImageFiles += chant.imageFiles?.length ?? (chant.imagePath != null ? 1 : 0);
          
          if (chant.sopranoFiles != null) pupitreCounts['soprano'] = (pupitreCounts['soprano'] ?? 0) + chant.sopranoFiles!.length;
          if (chant.altoFiles != null) pupitreCounts['alto'] = (pupitreCounts['alto'] ?? 0) + chant.altoFiles!.length;
          if (chant.tenorFiles != null) pupitreCounts['tenor'] = (pupitreCounts['tenor'] ?? 0) + chant.tenorFiles!.length;
          if (chant.basseFiles != null) pupitreCounts['basse'] = (pupitreCounts['basse'] ?? 0) + chant.basseFiles!.length;
          if (chant.tuttiFiles != null) pupitreCounts['tutti'] = (pupitreCounts['tutti'] ?? 0) + chant.tuttiFiles!.length;
        }
        
        print('📊 Résumé des fichiers:');
        print('   Audio: $totalAudioFiles');
        print('   PDF: $totalPdfFiles');
        print('   Images: $totalImageFiles');
        print('   Par pupitre: $pupitreCounts');
        
        setState(() {
          chants = validChants;
          loading = false;
        });
      } else {
        print('❌ Erreur lors du chargement: ${response.error}');
        // Si erreur mais qu'on a des chants en cache, les garder
        if (cachedChants.isEmpty) {
        setState(() {
          loading = false;
        });
          ToastService.error(
            context,
            'Erreur: ${response.error}',
          );
        } else {
          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      print('💥 Exception lors du chargement des chants: $e');
      setState(() {
        loading = false;
      });
      ToastService.error(
        context,
        'Erreur: $e',
      );
    }
  }

  void _syncChants() async {
    setState(() {
      syncing = true;
    });

    try {
      await _loadChants();
      ToastService.success(
        context,
        'Chants synchronisés',
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

  Future<void> _openAddFilesScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFilesToMesseSectionScreen(section: widget.section),
        ),
      );

    // Si des fichiers ont été ajoutés, recharger les chants
    if (result == true) {
      _loadChants();
    }
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
    if (_pupitres.isEmpty) return [];
    
    // Récupérer le nom du pupitre depuis la liste des pupitres
    final pupitre = _pupitres.firstWhere(
      (p) => p.id == pupitreId,
      orElse: () => _pupitres.first,
    );
    final pupitreNom = pupitre.nom.toLowerCase();
    
    List<String> files = [];
    
    // Vérifier si au moins un chant a des fichiers organisés par pupitre
    bool hasPupitreSpecificFiles = chants.any((chant) =>
      (chant.sopranoFiles != null && chant.sopranoFiles!.isNotEmpty) ||
      (chant.altoFiles != null && chant.altoFiles!.isNotEmpty) ||
      (chant.tenorFiles != null && chant.tenorFiles!.isNotEmpty) ||
      (chant.basseFiles != null && chant.basseFiles!.isNotEmpty) ||
      (chant.tuttiFiles != null && chant.tuttiFiles!.isNotEmpty)
    );
    
    // D'abord, chercher les fichiers spécifiques au pupitre pour TOUS les chants
    for (var chant in chants) {
      List<String>? chantFilesForPupitre;
      
      // Vérifier les fichiers par pupitre selon le nom
      if (pupitreNom.contains('soprano') || pupitreNom.contains('soprane')) {
        if (chant.sopranoFiles != null && chant.sopranoFiles!.isNotEmpty) {
          chantFilesForPupitre = chant.sopranoUrls;
        }
      } else if (pupitreNom.contains('alto') || pupitreNom.contains('mezzo')) {
        if (chant.altoFiles != null && chant.altoFiles!.isNotEmpty) {
          chantFilesForPupitre = chant.altoUrls;
        }
      } else if (pupitreNom.contains('ténor') || pupitreNom.contains('tenor')) {
        if (chant.tenorFiles != null && chant.tenorFiles!.isNotEmpty) {
          chantFilesForPupitre = chant.tenorUrls;
        }
      } else if (pupitreNom.contains('basse') || pupitreNom.contains('bariton')) {
        if (chant.basseFiles != null && chant.basseFiles!.isNotEmpty) {
          chantFilesForPupitre = chant.basseUrls;
        }
      } else if (pupitreNom.contains('tutti')) {
        if (chant.tuttiFiles != null && chant.tuttiFiles!.isNotEmpty) {
          chantFilesForPupitre = chant.tuttiUrls;
        }
      }
      
      // Ajouter uniquement les fichiers spécifiques au pupitre pour ce chant
      if (chantFilesForPupitre != null && chantFilesForPupitre.isNotEmpty) {
        files.addAll(chantFilesForPupitre);
      }
    }
    
    // Seulement si AUCUN fichier spécifique au pupitre n'a été trouvé ET
    // qu'aucun chant n'a de fichiers organisés par pupitre,
    // utiliser les fichiers audio généraux (fallback)
    if (files.isEmpty && !hasPupitreSpecificFiles) {
      print('⚠️ Aucun fichier spécifique trouvé pour pupitre $pupitreNom, utilisation des fichiers généraux');
      for (var chant in chants) {
        if (chant.audioFiles != null && chant.audioFiles!.isNotEmpty) {
        files.addAll(chant.audioUrls);
        } else if (chant.audioPath != null && chant.audioUrl != null) {
        files.add(chant.audioUrl!);
      }
    }
    } else if (files.isNotEmpty) {
      print('✅ ${files.length} fichier(s) spécifique(s) trouvé(s) pour pupitre $pupitreNom');
    } else {
      print('ℹ️ Aucun fichier pour pupitre $pupitreNom (les chants sont organisés par pupitre mais ce pupitre n\'a pas de fichiers)');
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
      body: Column(
        children: [
          const OfflineIndicator(),
          const Expanded(
            child: ShimmerListLoading(),
          ),
        ],
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
          if (_audioPlayerService.isPlaying)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: () => _audioPlayerService.pause(),
              tooltip: 'Arrêter la lecture',
            ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _openAddFilesScreen(),
            tooltip: 'Ajouter des fichiers',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: syncing ? null : _syncChants,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: loading
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFilesScreen,
        backgroundColor: AppConstance.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter des fichiers',
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
    // Collecter TOUS les fichiers PDF, images et texte de TOUS les chants
    List<String> pdfFiles = [];
    List<String> imageFiles = [];
    List<String> textFiles = [];
    
    for (var chant in chants) {
      // Collecter les fichiers PDF (listes et fichiers uniques)
      if (chant.pdfFiles != null && chant.pdfFiles!.isNotEmpty) {
        pdfFiles.addAll(chant.pdfUrls);
      }
      if (chant.pdfPath != null && chant.pdfUrl != null) {
        // Éviter les doublons
        if (!pdfFiles.contains(chant.pdfUrl!)) {
          pdfFiles.add(chant.pdfUrl!);
        }
      }
      
      // Collecter les fichiers images (listes et fichiers uniques)
      if (chant.imageFiles != null && chant.imageFiles!.isNotEmpty) {
        imageFiles.addAll(chant.imageUrls);
      }
      if (chant.imagePath != null && chant.imageUrl != null) {
        // Éviter les doublons
        if (!imageFiles.contains(chant.imageUrl!)) {
          imageFiles.add(chant.imageUrl!);
        }
      }
      
      // Pour les fichiers texte, on peut les détecter depuis les fichiers généraux
      // ou depuis d'autres sources si disponibles dans le futur
      // Pour l'instant, on peut détecter les fichiers .txt dans les chemins
    }
    
      // Détecter les fichiers texte depuis les chemins (si disponibles)
      // Cette logique peut être étendue si le backend envoie des fichiers texte
      // Pour l'instant, on se concentre sur PDF et images
    
    print('📁 Onglet Général - PDF: ${pdfFiles.length}, Images: ${imageFiles.length}, Texte: ${textFiles.length}');
    
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
          
          if (pdfFiles.isNotEmpty && (imageFiles.isNotEmpty || textFiles.isNotEmpty))
          const SizedBox(height: 16),
          
          // Fichiers Images
          if (imageFiles.isNotEmpty)
            _buildFileSection(
              title: 'Images',
              icon: Icons.image,
              color: Colors.blue,
              files: imageFiles,
            ),
          
          if (imageFiles.isNotEmpty && textFiles.isNotEmpty)
            const SizedBox(height: 16),
          
          // Fichiers Texte
          if (textFiles.isNotEmpty)
            _buildFileSection(
              title: 'Documents texte',
              icon: Icons.description,
              color: Colors.green,
              files: textFiles,
            ),
          
          // Message si aucun fichier
          if (pdfFiles.isEmpty && imageFiles.isEmpty && textFiles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun fichier PDF, image ou texte disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
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

  Widget _buildPupitreTab(String pupitreName, List<String> files, Color color) {
    print('🎭 Onglet $pupitreName - ${files.length} fichier(s)');
    
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
              print('   📄 Fichier ${index + 1}: $file');
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
    
    // Obtenir le chemin local si le fichier est téléchargé (pour les images)
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
    
    // Fonction pour ouvrir le fichier selon son type (comme dans folder_detail_screen et recordings_history)
    Future<void> openFile() async {
      // Vérifier si le fichier est en cours de téléchargement
      if (isDownloading) {
        ToastService.info(
          context,
          'Téléchargement en cours, veuillez patienter...',
        );
        return;
      }

      try {
        // Construire l'URL complète si nécessaire
        final isRemoteUrl = file.startsWith('http://') || file.startsWith('https://');
        String fileUrl = file;
        
        if (!isRemoteUrl && !file.startsWith('/')) {
          // C'est un chemin relatif, construire l'URL complète
          fileUrl = '${AppConstance.baseURL}/storage/$file';
        } else if (!isRemoteUrl) {
          // C'est déjà un chemin local, utiliser directement
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
        
        // Pour les URLs distantes, vérifier si déjà téléchargé
        String? localPath = await LocalFileService.getLocalFilePath(fileUrl);
        
        if (localPath == null) {
          // Télécharger le fichier
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

          // Mettre à jour le statut
          final newStatus = await LocalFileService.getFileStatus(fileUrl);
          setState(() {
            _fileStatuses[file] = newStatus;
          });
        }

        // Vérifier que le fichier existe
        final localFile = File(localPath);
        if (!await localFile.exists()) {
          throw Exception('Le fichier n\'existe pas: ${localPath.split('/').last}');
        }

        // Ouvrir le fichier selon son type avec le chemin local (comme dans recordings_history)
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
            // Pour les images téléchargées, afficher une miniature (comme dans folder_detail_screen)
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
                            return Icon(
                              Icons.image,
                              color: color,
                              size: 24,
                            );
                          },
                        ),
                      );
                    }
                  }
                  return Icon(
                    Icons.image,
                    color: color,
                    size: 24,
                  );
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
                  Row(
                    children: [
                      Text(
                        _getFileTypeLabel(file),
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
                  const SizedBox(height: 2),
                  _buildAuthorRow(file),
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

  // Jouer un audio avec un chemin local (comme dans recordings_history)
  Future<void> _playAudioLocal(String localPath) async {
    try {
      // Vérifier que le fichier existe
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Le fichier audio n\'existe pas: ${localPath.split('/').last}');
      }
      
      // Utiliser GlobalAudioPlayerService directement avec le chemin local (comme dans recordings_history)
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

  // Afficher un PDF avec un chemin local
  Future<void> _viewPdfLocal(String localPath) async {
    try {
      // Vérifier que le fichier existe
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Le fichier PDF n\'existe pas: ${localPath.split('/').last}');
      }
      
      // Ouvrir le PDF avec PdfService
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

  // Afficher une image avec un chemin local (comme dans folder_detail_screen)
  Future<void> _viewImageLocal(String localPath) async {
    try {
      // Vérifier que le fichier existe
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Le fichier image n\'existe pas: ${localPath.split('/').last}');
      }
      
      final imageName = localPath.split('/').last;
      
      // Ouvrir l'image avec ImageViewerScreen comme dans folder_detail_screen
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

  String _getFileTypeLabel(String file) {
    if (_isAudioFile(file)) return 'Fichier audio';
    if (_isPdfFile(file)) return 'Document PDF';
    if (_isImageFile(file)) return 'Image';
    return 'Fichier';
  }

  Widget _buildAuthorRow(String file) {
    // Trouver le chant auquel ce fichier appartient
    final parentChant = chants.firstWhere(
      (c) {
        final urls = [
          if (c.pdfPath != null) c.pdfUrl,
          if (c.imagePath != null) c.imageUrl,
          if (c.audioPath != null) c.audioUrl,
          ...?c.pdfUrls,
          ...?c.imageUrls,
          ...?c.audioUrls,
          ...?c.sopranoUrls,
          ...?c.altoUrls,
          ...?c.tenorUrls,
          ...?c.basseUrls,
          ...?c.tuttiUrls,
        ];
        return (urls.contains(file));
      },
      orElse: () => chants.isEmpty 
          ? ChantDeMesse(
              id: 0, 
              titre: '', 
              sectionId: 0, 
              ordre: 0, 
              active: true, 
              createdAt: DateTime.now(), 
              updatedAt: DateTime.now()
            ) 
          : chants.first,
    );

    final author = parentChant.userName ?? 'Maestro';

    return Row(
      children: [
        Icon(Icons.person, size: 10, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          'Par $author',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Écran de visionneuse d'images avec zoom et navigation (identique à folder_detail_screen)
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
        backgroundColor: Colors.black.withOpacity(0.7),
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
        child: _buildImageWidget(),
          ),
        );
      }

  Widget _buildImageWidget() {
    // Toujours utiliser Image.file car l'image est téléchargée localement avant d'être affichée
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      panEnabled: true,
      scaleEnabled: true,
      child: Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white70,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger l\'image',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            imagePath,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
