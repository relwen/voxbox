import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/creation_folder.dart';
import 'package:voxbox/models/creation_item.dart';
import 'package:voxbox/models/chorale_pupitre.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/creation_folder_service.dart';
import 'package:voxbox/services/global_audio_player_service.dart';
import 'package:voxbox/view/creations/add_item_dialog.dart';

class FolderDetailScreen extends StatefulWidget {
  final CreationFolder folder;

  const FolderDetailScreen({
    super.key,
    required this.folder,
  });

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> with SingleTickerProviderStateMixin {
  final CreationFolderService _folderService = CreationFolderService();
  final GlobalAudioPlayerService _audioPlayerService = GlobalAudioPlayerService();
  late CreationFolder _currentFolder;
  bool _isLoading = false;
  List<ChoralePupitre> _pupitres = [];
  TabController? _tabController;
  User? _currentUser;
  bool _isLoadingPupitres = true;
  
  @override
  void initState() {
    super.initState();
    _currentFolder = widget.folder;
    _loadUserAndPupitres();
    _setupAudioListeners();
  }
  
  void _setupAudioListeners() {
    // Écouter les changements du lecteur audio pour rafraîchir l'UI
    _audioPlayerService.isPlayingStream.listen((_) {
      if (mounted) setState(() {});
    });
    _audioPlayerService.audioInfoStream.listen((_) {
      if (mounted) setState(() {});
    });
  }


  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndPupitres() async {
    try {
      // Charger l'utilisateur depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? userString = prefs.getString('user');
      if (userString != null) {
        Map<String, dynamic> userMap = jsonDecode(userString);
        _currentUser = User.fromJson(userMap);
        
        // Charger les pupitres de la chorale si l'utilisateur a une chorale
        if (_currentUser?.choraleId != null) {
          await _loadPupitres(_currentUser!.choraleId!);
        } else {
          setState(() {
            _isLoadingPupitres = false;
            _tabController = TabController(length: 1, vsync: this); // Seulement Général
          });
        }
      } else {
        setState(() {
          _isLoadingPupitres = false;
          _tabController = TabController(length: 1, vsync: this); // Seulement Général
        });
      }
    } catch (e) {
      print('Erreur lors du chargement de l\'utilisateur: $e');
      setState(() {
        _isLoadingPupitres = false;
        _tabController = TabController(length: 1, vsync: this); // Seulement Général
      });
    }
  }

  Future<void> _loadPupitres(int choraleId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstance.baseURL}/api/chorales/$choraleId/pupitres'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          List<ChoralePupitre> pupitres = (responseData['data'] as List)
              .map((p) => ChoralePupitre.fromJson(p))
              .toList();
          
          // Trier par ordre
          pupitres.sort((a, b) => a.order.compareTo(b.order));
          
          setState(() {
            _pupitres = pupitres;
            // Créer TabController avec pupitres + 1 (pour Général)
            _tabController?.dispose();
            _tabController = TabController(length: _pupitres.length + 1, vsync: this);
            _isLoadingPupitres = false;
          });
        } else {
          setState(() {
            _pupitres = [];
            _tabController?.dispose();
            _tabController = TabController(length: 1, vsync: this);
            _isLoadingPupitres = false;
          });
        }
      } else {
        setState(() {
          _pupitres = [];
          _tabController?.dispose();
          _tabController = TabController(length: 1, vsync: this);
          _isLoadingPupitres = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des pupitres: $e');
      setState(() {
        _pupitres = [];
        _tabController?.dispose();
        _tabController = TabController(length: 1, vsync: this);
        _isLoadingPupitres = false;
      });
    }
  }

  Future<void> _refreshFolder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final folders = await _folderService.getFolders();
      final updatedFolder = folders.firstWhere(
        (folder) => folder.id == _currentFolder.id,
        orElse: () => _currentFolder,
      );
      
      setState(() {
        _currentFolder = updatedFolder;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Erreur lors du chargement');
    }
  }

  Future<void> _addItem() async {
    final result = await showDialog<CreationItem>(
      context: context,
      builder: (context) => AddItemDialog(folderId: _currentFolder.id),
    );

    if (result != null) {
      await _refreshFolder();
      _showSuccessSnackBar('Élément ajouté avec succès');
    }
  }

  Future<void> _deleteItem(CreationItem item) async {
    final confirmed = await _showDeleteConfirmation(item.name);
    if (confirmed) {
      final success = await _folderService.removeItemFromFolder(
        _currentFolder.id,
        item.id,
      );
      if (success) {
        await _refreshFolder();
        _showSuccessSnackBar('Élément supprimé');
      } else {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String itemName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'élément'),
        content: Text('Êtes-vous sûr de vouloir supprimer "$itemName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: _currentFolder.name,
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: _getColorFromString(_currentFolder.color ?? '#2196F3'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _addItem,
            tooltip: 'Ajouter un élément',
          ),
        ],
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
        child: _isLoading || _isLoadingPupitres || _tabController == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  // En-tête du dossier
                  _buildFolderHeader(),
                  
                  // TabBar pour les pupitres
                  if (_pupitres.isNotEmpty)
                    Container(
                      color: Colors.grey[900],
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: _pupitres.length > 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.6),
                        indicatorColor: _getColorFromString(_currentFolder.color ?? '#2196F3'),
                        tabs: [
                          const Tab(text: 'Général'),
                          ..._pupitres.map((pupitre) => Tab(
                            text: pupitre.nom,
                            icon: pupitre.icon != null 
                                ? Icon(_getIconFromString(pupitre.icon!))
                                : null,
                          )),
                        ],
                      ),
                    ),
                  
                  // Liste des éléments selon l'onglet sélectionné
                  Expanded(
                    child: _currentFolder.items.isEmpty
                        ? _buildEmptyState()
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              // Onglet Général
                              _buildItemsListForTab(null),
                              // Onglets pupitres
                              ..._pupitres.map((pupitre) => _buildItemsListForTab(pupitre)),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFolderHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getColorFromString(_currentFolder.color ?? '#2196F3').withOpacity(0.2),
            _getColorFromString(_currentFolder.color ?? '#2196F3').withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColorFromString(_currentFolder.color ?? '#2196F3').withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Icône du dossier
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getColorFromString(_currentFolder.color ?? '#2196F3'),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconFromString(_currentFolder.icon ?? 'folder'),
              color: Colors.white,
              size: 30,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Informations du dossier
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentFolder.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_currentFolder.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currentFolder.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description, size: 16, color: Colors.white.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentFolder.totalItems} éléments',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      if (_currentFolder.audioCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.audiotrack, size: 16, color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentFolder.audioCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      if (_currentFolder.imageCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, size: 16, color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentFolder.imageCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      if (_currentFolder.textCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.text_fields, size: 16, color: Colors.white.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentFolder.textCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconFromString(_currentFolder.icon ?? 'folder'),
            size: 80,
            color: _getColorFromString(_currentFolder.color ?? '#2196F3').withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Dossier vide',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier élément à ce dossier',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un élément'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getColorFromString(_currentFolder.color ?? '#2196F3'),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsListForTab(ChoralePupitre? pupitre) {
    // Filtrer les éléments selon l'onglet
    List<CreationItem> filteredItems;
    
    if (pupitre == null) {
      // Onglet Général : images, textes, et fichiers audio sans pupitre ou non assignés
      filteredItems = _currentFolder.items.where((item) {
        if (item.type == CreationType.image || item.type == CreationType.text) {
          return true;
        }
        if (item.type == CreationType.audio) {
          // Vérifier si le fichier audio n'est pas assigné à un pupitre
          final pupitreNom = _getPupitreFromItem(item);
          return pupitreNom == null;
        }
        return false;
      }).toList();
    } else {
      // Onglet pupitre : uniquement les fichiers audio de ce pupitre
      filteredItems = _currentFolder.items.where((item) {
        if (item.type == CreationType.audio) {
          final itemPupitreNom = _getPupitreFromItem(item);
          // Comparer le nom du pupitre (insensible à la casse)
          return itemPupitreNom != null && 
                 itemPupitreNom.toLowerCase() == pupitre.nom.toLowerCase();
        }
        return false;
      }).toList();
    }
    
    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              pupitre == null ? Icons.folder_open : Icons.person_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              pupitre == null 
                  ? 'Aucun élément dans Général'
                  : 'Aucun fichier audio pour le pupitre ${pupitre.nom}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  String? _getPupitreFromItem(CreationItem item) {
    // Vérifier dans les métadonnées
    if (item.metadata != null) {
      if (item.metadata!['pupitre'] != null) {
        return item.metadata!['pupitre'].toString();
      }
      if (item.metadata!['pupitre_nom'] != null) {
        return item.metadata!['pupitre_nom'].toString();
      }
      if (item.metadata!['voice_part'] != null) {
        return item.metadata!['voice_part'].toString();
      }
    }
    
    // Si pas dans métadonnées, essayer de détecter depuis le nom du fichier
    if (item.name != null) {
      final nameLower = item.name!.toLowerCase();
      for (var pupitre in _pupitres) {
        if (nameLower.contains(pupitre.nom.toLowerCase())) {
          return pupitre.nom;
        }
      }
    }
    
    return null;
  }

  Widget _buildItemCard(CreationItem item) {
    if (item.type == CreationType.audio) {
      return _buildAudioCard(item);
    } else if (item.type == CreationType.image) {
      return _buildImageCard(item);
    } else {
      // Pour les textes, garder l'ancien style
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _openItem(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getItemColor(item.type),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getItemIcon(item.type),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteItem(item);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAudioCard(CreationItem item) {
    if (item.filePath == null) {
      return const SizedBox.shrink();
    }
    
    final isCurrentlyPlaying = _audioPlayerService.currentAudioPath == item.filePath;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(isCurrentlyPlaying ? 0.15 : 0.08),
            Colors.white.withOpacity(isCurrentlyPlaying ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentlyPlaying
              ? AppConstance.primary.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: isCurrentlyPlaying ? 2 : 1,
        ),
        boxShadow: isCurrentlyPlaying
            ? [
                BoxShadow(
                  color: AppConstance.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Bouton Play/Pause
                GestureDetector(
                  onTap: () async {
                    if (isCurrentlyPlaying && _audioPlayerService.isPlaying) {
                      await _audioPlayerService.pause();
                    } else {
                      await _playAudio(item);
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCurrentlyPlaying && _audioPlayerService.isPlaying
                            ? [AppConstance.primary, AppConstance.primary.withOpacity(0.8)]
                            : [Colors.grey.shade700, Colors.grey.shade900],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isCurrentlyPlaying && _audioPlayerService.isPlaying
                              ? AppConstance.primary.withOpacity(0.4)
                              : Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isCurrentlyPlaying && _audioPlayerService.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Infos de l'audio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<Duration>(
                        stream: _audioPlayerService.positionStream,
                        builder: (context, snapshot) {
                          final currentPosition = isCurrentlyPlaying
                              ? _audioPlayerService.currentPosition
                              : (item.duration != null ? Duration(seconds: item.duration!) : Duration.zero);
                          return Text(
                            _formatDuration(currentPosition),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontFamily: 'monospace',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(item.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu d'options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteItem(item);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text('Supprimer', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Barre de progression si en cours de lecture
          if (isCurrentlyPlaying)
            StreamBuilder<Duration>(
              stream: _audioPlayerService.positionStream,
              builder: (context, snapshot) {
                final position = _audioPlayerService.currentPosition;
                final duration = _audioPlayerService.totalDuration;
                final progress = duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppConstance.primary,
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: AppConstance.primary,
                          overlayColor: AppConstance.primary.withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (value) {
                            final newPosition = Duration(
                              milliseconds: (value * duration.inMilliseconds).round(),
                            );
                            _audioPlayerService.seek(newPosition);
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _formatDuration(position),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.replay_10),
                                color: Colors.white.withOpacity(0.8),
                                iconSize: 24,
                                onPressed: () => _audioPlayerService.seekBackward(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.forward_10),
                                color: Colors.white.withOpacity(0.8),
                                iconSize: 24,
                                onPressed: () => _audioPlayerService.seekForward(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          Flexible(
                            child: Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard(CreationItem item) {
    if (item.filePath == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Miniature de l'image
            GestureDetector(
              onTap: () => _openItem(item),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(item.filePath!),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppConstance.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image,
                        color: AppConstance.secondary,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Infos de l'image
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.fileSize != null)
                    Text(
                      item.formattedFileSize,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Menu d'options
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteItem(item);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Supprimer', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playAudio(CreationItem item) async {
    if (item.filePath == null) return;
    try {
      await _audioPlayerService.playAudio(item.filePath!, title: item.name);
    } catch (e) {
      _showErrorSnackBar('Erreur de lecture: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _openItem(CreationItem item) {
    switch (item.type) {
      case CreationType.audio:
        // La lecture se fait directement depuis la carte
        if (item.filePath != null) {
          _playAudio(item);
        }
        break;
      case CreationType.image:
        if (item.filePath != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageViewerScreen(
                imagePath: item.filePath!,
                imageName: item.name,
              ),
            ),
          );
        } else {
          _showErrorSnackBar('Le fichier image n\'est pas disponible');
        }
        break;
      case CreationType.text:
        _showErrorSnackBar('Éditeur de texte en cours de développement');
        break;
    }
  }

  Color _getColorFromString(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (e) {
      return AppConstance.primary;
    }
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'folder':
        return Icons.folder;
      case 'music':
        return Icons.music_note;
      case 'image':
        return Icons.image;
      case 'text':
        return Icons.text_fields;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      default:
        return Icons.folder;
    }
  }

  Color _getItemColor(CreationType type) {
    switch (type) {
      case CreationType.audio:
        return AppConstance.primary;
      case CreationType.image:
        return AppConstance.secondary;
      case CreationType.text:
        return AppConstance.accent;
    }
  }

  IconData _getItemIcon(CreationType type) {
    switch (type) {
      case CreationType.audio:
        return Icons.audiotrack;
      case CreationType.image:
        return Icons.image;
      case CreationType.text:
        return Icons.text_fields;
    }
  }
}

/// Écran de visionneuse d'images avec zoom et navigation
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
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          panEnabled: true,
          scaleEnabled: true,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
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
            },
          ),
        ),
      ),
    );
  }
}
