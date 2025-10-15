import 'package:flutter/material.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/services/partition_service.dart';
import 'package:voxbox/services/category_service.dart';
import 'package:voxbox/models/partition.dart';
import 'package:voxbox/models/category.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:voxbox/view/partitions/add_partition.dart';
import 'package:voxbox/widgets/sync_status_widget.dart';

class PartitionsScreen extends StatefulWidget {
  const PartitionsScreen({super.key});

  @override
  State<PartitionsScreen> createState() => _PartitionsScreenState();
}

class _PartitionsScreenState extends State<PartitionsScreen> {
  List<Partition> partitions = [];
  List<Category> categories = [];
  bool isLoading = true;
  bool hasInternet = true;
  String? errorMessage;
  int? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkConnectivity();
  }

  void _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      hasInternet = connectivityResult != ConnectivityResult.none;
    });
  }

  void _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Charger les catégories
      var categoryResponse = await CategoryService.getCategories();
      if (categoryResponse.error == null) {
        setState(() {
          categories = categoryResponse.data as List<Category>;
        });
      }

      // Charger les partitions
      var partitionResponse = await PartitionService.getPartitions();
      if (partitionResponse.error == null) {
        setState(() {
          partitions = partitionResponse.data as List<Partition>;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = partitionResponse.error;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des données';
        isLoading = false;
      });
    }
  }

  void _refreshPartitions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var response = await PartitionService.getPartitions(forceRefresh: true);
      if (response.error == null) {
        setState(() {
          partitions = response.data as List<Partition>;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Partitions synchronisées avec succès')),
        );
      } else {
        setState(() {
          errorMessage = response.error;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors de la synchronisation';
        isLoading = false;
      });
    }
  }

  void _addPartition() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPartitionScreen()),
    );
    
    if (result == true) {
      // Rafraîchir la liste après ajout
      _refreshPartitions();
    }
  }

  void _downloadFile(Partition partition, String fileType) async {
    bool downloaded = await PartitionService.downloadFile(partition, fileType);
    if (downloaded) {
      setState(() {
        // Mettre à jour la partition dans la liste
        int index = partitions.indexWhere((p) => p.id == partition.id);
        if (index != -1) {
          partitions[index] = partition;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fichier téléchargé avec succès')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement')),
      );
    }
  }

  void _deleteFile(Partition partition, String fileType) async {
    bool deleted = await PartitionService.deleteDownloadedFile(partition, fileType);
    if (deleted) {
      setState(() {
        // Mettre à jour la partition dans la liste
        int index = partitions.indexWhere((p) => p.id == partition.id);
        if (index != -1) {
          partitions[index] = partition;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fichier supprimé')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression')),
      );
    }
  }

  List<Partition> get filteredPartitions {
    if (selectedCategoryId == null) {
      return partitions;
    }
    return partitions.where((p) => p.categoryId == selectedCategoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: "Partitions",
          size: 20,
          color: Colors.white,
          fontweight: FontWeight.w800,
        ),
        foregroundColor: Colors.white,
        backgroundColor: theme,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addPartition,
            tooltip: 'Ajouter une partition',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: hasInternet ? _refreshPartitions : null,
            tooltip: 'Synchroniser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de synchronisation
          SyncStatusWidget(
            onSyncPressed: hasInternet ? _refreshPartitions : null,
          ),
          
          // Indicateur de connectivité
          if (!hasInternet)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              color: Colors.orange,
              child: Text(
                'Mode hors ligne - Données locales',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Filtres par catégorie
          if (categories.isNotEmpty)
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1, // +1 pour "Toutes"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Bouton "Toutes"
                    return Container(
                      margin: EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('Toutes'),
                        selected: selectedCategoryId == null,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategoryId = null;
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: AppConstance.primary.withOpacity(0.2),
                        checkmarkColor: AppConstance.primary,
                      ),
                    );
                  }
                  
                  final category = categories[index - 1];
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (category.icon != null) ...[
                            Icon(
                              _getIconData(category.icon!),
                              size: 16,
                              color: selectedCategoryId == category.id 
                                  ? AppConstance.primary 
                                  : _getColorFromHex(category.color),
                            ),
                            SizedBox(width: 4),
                          ],
                          Text(category.name),
                        ],
                      ),
                      selected: selectedCategoryId == category.id,
                      onSelected: (selected) {
                        setState(() {
                          selectedCategoryId = selected ? category.id : null;
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: _getColorFromHex(category.color).withOpacity(0.2),
                      checkmarkColor: _getColorFromHex(category.color),
                    ),
                  );
                },
              ),
            ),
          
          // Contenu principal
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : filteredPartitions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_note, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  selectedCategoryId == null 
                                      ? 'Aucune partition disponible'
                                      : 'Aucune partition dans cette catégorie',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                if (hasInternet) ...[
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshPartitions,
                                    child: Text('Synchroniser'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredPartitions.length,
                            itemBuilder: (context, index) {
                              final partition = filteredPartitions[index];
                              return _buildPartitionCard(partition);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartitionCard(Partition partition) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre et catégorie
            Row(
              children: [
                Expanded(
                  child: Text(
                    partition.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorFromHex(partition.categoryColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getColorFromHex(partition.categoryColor),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (partition.categoryIcon != null) ...[
                        Icon(
                          _getIconData(partition.categoryIcon!),
                          size: 14,
                          color: _getColorFromHex(partition.categoryColor),
                        ),
                        SizedBox(width: 4),
                      ],
                      Text(
                        partition.categoryName ?? 'Catégorie',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getColorFromHex(partition.categoryColor),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Description
            if (partition.description != null) ...[
              SizedBox(height: 8),
              Text(
                partition.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            
            // Chorale
            if (partition.choraleName != null) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    partition.choraleName!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            
            SizedBox(height: 16),
            
            // Fichiers disponibles
            _buildFileSection(partition),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection(Partition partition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fichiers disponibles:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        
        // Fichier audio
        if (partition.hasAudio())
          _buildFileItem(
            'Audio',
            Icons.audio_file,
            partition.localAudioPath != null,
            () => partition.localAudioPath != null 
                ? _deleteFile(partition, 'audio')
                : _downloadFile(partition, 'audio'),
          ),
        
        // Fichier PDF
        if (partition.hasPdf())
          _buildFileItem(
            'PDF',
            Icons.picture_as_pdf,
            partition.localPdfPath != null,
            () => partition.localPdfPath != null 
                ? _deleteFile(partition, 'pdf')
                : _downloadFile(partition, 'pdf'),
          ),
        
        // Image
        if (partition.hasImage())
          _buildFileItem(
            'Image',
            Icons.image,
            partition.localImagePath != null,
            () => partition.localImagePath != null 
                ? _deleteFile(partition, 'image')
                : _downloadFile(partition, 'image'),
          ),
      ],
    );
  }

  Widget _buildFileItem(String label, IconData icon, bool isDownloaded, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDownloaded ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDownloaded ? Colors.green : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDownloaded ? Colors.green : Colors.grey[600],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDownloaded ? Colors.green[800] : Colors.grey[700],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isDownloaded ? Icons.delete : Icons.download,
              color: isDownloaded ? Colors.red : AppConstance.primary,
              size: 20,
            ),
            onPressed: onPressed,
            tooltip: isDownloaded ? 'Supprimer' : 'Télécharger',
          ),
        ],
      ),
    );
  }

  // Convertir le nom d'icône en IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'music_note':
        return Icons.music_note;
      case 'church':
        return Icons.church;
      case 'library_music':
        return Icons.library_music;
      case 'favorite':
        return Icons.favorite;
      case 'flag':
        return Icons.flag;
      default:
        return Icons.category;
    }
  }

  // Convertir la couleur hex en Color
  Color _getColorFromHex(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return Colors.grey;
    }
    
    try {
      String hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Ajouter l'alpha si absent
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
