import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/models/category.dart';
import 'package:voxbox/models/partition.dart';
import 'package:voxbox/services/partition_service.dart';
import 'package:voxbox/services/toast_service.dart';

class SectionPartitionsScreen extends StatefulWidget {
  final Category section;

  const SectionPartitionsScreen({
    super.key,
    required this.section,
  });

  @override
  State<SectionPartitionsScreen> createState() =>
      _SectionPartitionsScreenState();
}

class _SectionPartitionsScreenState extends State<SectionPartitionsScreen> {
  List<Partition> sectionPartitions = [];
  bool loading = false;
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    _loadPartitions();
  }

  Future<void> _loadPartitions() async {
    setState(() {
      loading = true;
    });

    try {
      var partitionResponse = await PartitionService.getPartitions();
      if (partitionResponse.error == null) {
        List<Partition> allPartitions =
            partitionResponse.data as List<Partition>;
        setState(() {
          sectionPartitions = allPartitions
              .where((p) => p.categoryId == widget.section.id)
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _syncPartitions() async {
    setState(() {
      syncing = true;
    });

    try {
      var response = await PartitionService.getPartitions(forceRefresh: true);
      if (response.error == null) {
        List<Partition> allPartitions = response.data as List<Partition>;
        setState(() {
          sectionPartitions = allPartitions
              .where((p) => p.categoryId == widget.section.id)
              .toList();
          syncing = false;
        });
        ToastService.success(
          context,
          'Synchronisation terminée',
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

  String _getSectionName(String fullName) {
    // Extraire le nom de la section (après " - ")
    if (fullName.contains(' - ')) {
      return fullName.split(' - ')[1];
    }
    return fullName;
  }

  void _playAudio(Partition partition) async {
    if (partition.audioPath != null) {
      try {
        // TODO: Implémenter la lecture audio
        ToastService.info(
          context,
          'Lecture audio: ${partition.title}',
        );
      } catch (e) {
        ToastService.error(
          context,
          'Erreur de lecture: $e',
        );
      }
    } else {
      ToastService.warning(
        context,
        'Aucun fichier audio disponible',
      );
    }
  }

  void _downloadFile(Partition partition, String fileType) async {
    try {
      // TODO: Implémenter le téléchargement
      ToastService.info(
        context,
        'Téléchargement $fileType: ${partition.title}',
      );
    } catch (e) {
      ToastService.error(
        context,
        'Erreur de téléchargement: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String sectionName = _getSectionName(widget.section.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(sectionName),
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
            onPressed: syncing ? null : _syncPartitions,
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
          : sectionPartitions.isEmpty
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
                        'Aucune partition disponible',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Les partitions de cette section apparaîtront ici',
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
                  itemCount: sectionPartitions.length,
                  itemBuilder: (context, index) {
                    Partition partition = sectionPartitions[index];

                    return Card(
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(int.parse(partition
                                  .categoryColor
                                  ?.replaceAll('#', '0xFF') ??
                              '0xFF2196F3')),
                          child: Icon(
                            Icons.music_note,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          partition.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (partition.description != null)
                              Text(partition.description!),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.category, size: 16),
                                SizedBox(width: 4),
                                Text(partition.categoryName ?? 'Section'),
                                SizedBox(width: 16),
                                Icon(Icons.group, size: 16),
                                SizedBox(width: 4),
                                Text(partition.choraleName ?? 'Chorale'),
                              ],
                            ),
                            // if (partition.userName != null) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.person,
                                    size: 16, color: Colors.grey[500]),
                                SizedBox(width: 4),
                                Text(
                                  'Par ${partition.userName}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            // ],
                            SizedBox(height: 4),
                            Row(
                              children: [
                                if (partition.audioPath != null)
                                  Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Audio',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                if (partition.pdfPath != null)
                                  Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'PDF',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                if (partition.imagePath != null)
                                  Container(
                                    margin: EdgeInsets.only(right: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Image',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (partition.audioPath != null)
                              IconButton(
                                onPressed: () => _playAudio(partition),
                                icon: Icon(Icons.play_arrow),
                                tooltip: 'Lire audio',
                              ),
                            if (partition.pdfPath != null)
                              IconButton(
                                onPressed: () =>
                                    _downloadFile(partition, 'PDF'),
                                icon: Icon(Icons.picture_as_pdf),
                                tooltip: 'Télécharger PDF',
                              ),
                            if (partition.imagePath != null)
                              IconButton(
                                onPressed: () =>
                                    _downloadFile(partition, 'Image'),
                                icon: Icon(Icons.image),
                                tooltip: 'Télécharger Image',
                              ),
                          ],
                        ),
                        onTap: () {
                          // Afficher les détails de la partition
                          _showPartitionDetails(partition);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _showPartitionDetails(Partition partition) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(partition.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (partition.description != null)
                Text('Description: ${partition.description}'),
              SizedBox(height: 8),
              Text('Catégorie: ${partition.categoryName ?? 'N/A'}'),
              Text('Chorale: ${partition.choraleName ?? 'N/A'}'),
              SizedBox(height: 16),
              Text('Fichiers disponibles:'),
              SizedBox(height: 8),
              if (partition.audioPath != null)
                ListTile(
                  leading: Icon(Icons.audiotrack, color: Colors.green),
                  title: Text('Audio'),
                  trailing: IconButton(
                    onPressed: () => _playAudio(partition),
                    icon: Icon(Icons.play_arrow),
                  ),
                ),
              if (partition.pdfPath != null)
                ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text('PDF'),
                  trailing: IconButton(
                    onPressed: () => _downloadFile(partition, 'PDF'),
                    icon: Icon(Icons.download),
                  ),
                ),
              if (partition.imagePath != null)
                ListTile(
                  leading: Icon(Icons.image, color: Colors.blue),
                  title: Text('Image'),
                  trailing: IconButton(
                    onPressed: () => _downloadFile(partition, 'Image'),
                    icon: Icon(Icons.download),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}
