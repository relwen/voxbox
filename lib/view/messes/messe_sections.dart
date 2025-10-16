import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/models/category.dart';
import 'package:voxbox/models/partition.dart';
import 'package:voxbox/services/partition_service.dart';
import 'package:voxbox/services/category_service.dart';

class MesseSectionsScreen extends StatefulWidget {
  final Category messeFolder;

  const MesseSectionsScreen({
    super.key,
    required this.messeFolder,
  });

  @override
  State<MesseSectionsScreen> createState() => _MesseSectionsScreenState();
}

class _MesseSectionsScreenState extends State<MesseSectionsScreen> {
  List<Category> messeSections = [];
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
        
        // Filtrer les sections de cette messe
        String messeName = widget.messeFolder.name;
        setState(() {
          messeSections = allCategories.where((cat) => 
            cat.name.startsWith('$messeName - ')
          ).toList();
        });
      }

      // Charger toutes les partitions pour compter les éléments par section
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

  String _getSectionName(String fullName) {
    // Extraire le nom de la section (après " - ")
    if (fullName.contains(' - ')) {
      return fullName.split(' - ')[1];
    }
    return fullName;
  }

  IconData _getIconForSection(String sectionName) {
    String name = sectionName.toLowerCase();
    if (name.contains('kyrié') || name.contains('kyrie')) return Icons.music_note;
    if (name.contains('gloria')) return Icons.star;
    if (name.contains('sanctus')) return Icons.church;
    if (name.contains('agnus')) return Icons.favorite;
    return Icons.music_note;
  }

  void _openSection(Category section) {
    // TODO: Naviguer vers la liste des partitions de cette section
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de la section: ${_getSectionName(section.name)}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _syncSections() async {
    setState(() {
      syncing = true;
    });

    try {
      // Synchroniser les catégories
      var categoryResponse = await CategoryService.getCategories();
      if (categoryResponse.error == null) {
        List<Category> allCategories = categoryResponse.data as List<Category>;
        String messeName = widget.messeFolder.name;
        setState(() {
          messeSections = allCategories.where((cat) => 
            cat.name.startsWith('$messeName - ')
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
        title: Text(widget.messeFolder.name),
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
            onPressed: syncing ? null : _syncSections,
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
          : messeSections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune section disponible',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Les sections de messe apparaîtront ici',
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
                  itemCount: messeSections.length,
                  itemBuilder: (context, index) {
                    Category section = messeSections[index];
                    int partitionCount = _getPartitionCountForCategory(section.id);
                    String sectionName = _getSectionName(section.name);
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse(section.color?.replaceAll('#', '0xFF') ?? '0xFF2196F3')),
                          child: Icon(
                            _getIconForSection(sectionName),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          sectionName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.description ?? 'Section de messe',
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
                                Icon(Icons.queue_music, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  'Section de messe',
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
                          _openSection(section);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _showAddSectionDialog();
        },
        backgroundColor: theme,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showAddSectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ajouter une section'),
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
}
