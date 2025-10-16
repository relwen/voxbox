import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/models/partition.dart';
import 'package:voxbox/models/category.dart';
import 'package:voxbox/services/partition_service.dart';
import 'package:voxbox/services/category_service.dart';
import 'package:voxbox/view/messes/messe_sections.dart';

class MessesScreen extends StatefulWidget {
  const MessesScreen({super.key});

  @override
  State<MessesScreen> createState() => _MessesScreenState();
}

class _MessesScreenState extends State<MessesScreen> {
  List<Category> messeFolders = [];
  List<Partition> allPartitions = [];
  bool loading = false;
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      loading = true;
    });

    try {
      // Charger les catégories
      var categoryResponse = await CategoryService.getCategories();
      if (categoryResponse.error == null) {
        List<Category> allCategories = categoryResponse.data as List<Category>;
        
        // Filtrer les catégories de messes (exclure la catégorie générale "Messes" et les sections)
        setState(() {
          messeFolders = allCategories.where((cat) => 
            cat.name.toLowerCase() != 'messes' && 
            !cat.name.contains(' - ') && // Exclure les sections (qui contiennent " - ")
            (cat.name.toLowerCase().contains('st gabriel') ||
             cat.name.toLowerCase().contains('sympathie') ||
             cat.name.toLowerCase().contains('pentecote') ||
             cat.name.toLowerCase().contains('messe'))
          ).toList();
        });
      }

      // Charger toutes les partitions pour compter les éléments par dossier
      await _loadPartitions();
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _loadPartitions() async {
    var partitionResponse = await PartitionService.getPartitions();
    if (partitionResponse.error == null) {
      setState(() {
        allPartitions = partitionResponse.data as List<Partition>;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  int _getPartitionCountForCategory(int categoryId) {
    return allPartitions.where((p) => p.categoryId == categoryId).length;
  }

  IconData _getIconForMesseFolder(String folderName) {
    String name = folderName.toLowerCase();
    if (name.contains('st gabriel')) return Icons.church;
    if (name.contains('sympathie')) return Icons.favorite;
    if (name.contains('pentecote')) return Icons.local_fire_department;
    return Icons.folder;
  }

  void _openMesseFolder(Category messeFolder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MesseSectionsScreen(messeFolder: messeFolder),
      ),
    );
  }

  void _showAddMesseFolderDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter un dossier de messe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cette fonctionnalité sera disponible prochainement.'),
              SizedBox(height: 16),
              Text('Pour l\'instant, vous pouvez ajouter des partitions via l\'onglet "Partitions".'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncMesses() async {
    setState(() {
      syncing = true;
    });

    try {
      // Synchroniser les catégories
      var categoryResponse = await CategoryService.getCategories();
      if (categoryResponse.error == null) {
        List<Category> allCategories = categoryResponse.data as List<Category>;
        setState(() {
          messeFolders = allCategories.where((cat) => 
            cat.name.toLowerCase() != 'messes' && 
            !cat.name.contains(' - ') && // Exclure les sections (qui contiennent " - ")
            (cat.name.toLowerCase().contains('st gabriel') ||
             cat.name.toLowerCase().contains('sympathie') ||
             cat.name.toLowerCase().contains('pentecote') ||
             cat.name.toLowerCase().contains('messe'))
          ).toList();
        });
      }

      // Synchroniser les partitions
      var partitionResponse = await PartitionService.getPartitions(forceRefresh: true);
      if (partitionResponse.error == null) {
        setState(() {
          allPartitions = partitionResponse.data as List<Partition>;
          syncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronisation terminée'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          syncing = false;
        });
      }
    } catch (e) {
      setState(() {
        syncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Messes"),
        backgroundColor: theme,
        foregroundColor: Colors.white,
        actions: [
          if (syncing)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: SpinKitCircle(
                color: Colors.white,
                size: 20.0,
              ),
            ),
          IconButton(
            onPressed: syncing ? null : _syncMesses,
            icon: Icon(Icons.sync),
            tooltip: 'Synchroniser',
          ),
        ],
      ),
      body: loading
          ? Center(
              child: SpinKitCircle(
                color: theme,
                size: 50.0,
              ),
            )
          : messeFolders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucun dossier de messe disponible',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Les dossiers de messes apparaîtront ici',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: messeFolders.length,
                  itemBuilder: (context, index) {
                    Category messeFolder = messeFolders[index];
                    int partitionCount = _getPartitionCountForCategory(messeFolder.id);
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse(messeFolder.color?.replaceAll('#', '0xFF') ?? '0xFF2196F3')),
                          child: Icon(
                            _getIconForMesseFolder(messeFolder.name),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          messeFolder.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messeFolder.description ?? 'Dossier de messe',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.music_note, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  '$partitionCount partition${partitionCount > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(Icons.folder, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  'Dossier de messe',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _openMesseFolder(messeFolder);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _showAddMesseFolderDialog();
        },
        backgroundColor: theme,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}