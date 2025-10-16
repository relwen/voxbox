import 'package:flutter/material.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/view/messes/add_files_to_chant.dart';

class ChantDetailsScreen extends StatefulWidget {
  final ChantDeMesse chant;

  const ChantDetailsScreen({super.key, required this.chant});

  @override
  State<ChantDetailsScreen> createState() => _ChantDetailsScreenState();
}

class _ChantDetailsScreenState extends State<ChantDetailsScreen> with SingleTickerProviderStateMixin {
  bool loading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: widget.chant.titre,
          color: Colors.white,
          size: 18,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _addFiles(),
            tooltip: 'Ajouter des fichiers',
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implémenter le partage
            },
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
                        widget.chant.titre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.chant.description != null)
                        Text(
                          widget.chant.description!,
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
          
          // TabBar pour les pupitres
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppConstance.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppConstance.primary,
            tabs: const [
              Tab(text: 'Soprano', icon: Icon(Icons.person, size: 16)),
              Tab(text: 'Alto', icon: Icon(Icons.person, size: 16)),
              Tab(text: 'Ténor', icon: Icon(Icons.person, size: 16)),
              Tab(text: 'Basse', icon: Icon(Icons.person, size: 16)),
              Tab(text: 'Tutti', icon: Icon(Icons.group, size: 16)),
              Tab(text: 'Général', icon: Icon(Icons.folder, size: 16)),
            ],
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPupitreTab('Soprano', widget.chant.sopranoUrls, Colors.pink),
                _buildPupitreTab('Alto', widget.chant.altoUrls, Colors.orange),
                _buildPupitreTab('Ténor', widget.chant.tenorUrls, Colors.blue),
                _buildPupitreTab('Basse', widget.chant.basseUrls, Colors.brown),
                _buildPupitreTab('Tutti', widget.chant.tuttiUrls, Colors.purple),
                _buildGeneralTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPupitreTab(String pupitreName, List<String> files, Color color) {
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
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildFileItem(String file, int index, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(file),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fichier $index',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  file.split('/').last,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue),
            onPressed: () => _downloadFile(file),
            tooltip: 'Télécharger',
          ),
          if (_isAudioFile(file))
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () => _playAudio(file),
              tooltip: 'Lire',
            ),
          if (_isPdfFile(file))
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.orange),
              onPressed: () => _viewPdf(file),
              tooltip: 'Voir',
            ),
          if (_isImageFile(file))
            IconButton(
              icon: const Icon(Icons.visibility, color: Colors.purple),
              onPressed: () => _viewImage(file),
              tooltip: 'Voir',
            ),
        ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fichiers généraux (audio, PDF, images)
          if (widget.chant.audioFiles?.isNotEmpty == true || widget.chant.audioPath != null)
            _buildFileSection(
              title: 'Fichiers Audio',
              icon: Icons.audiotrack,
              color: Colors.green,
              files: widget.chant.audioFiles ?? (widget.chant.audioPath != null ? [widget.chant.audioPath!] : []),
            ),

          const SizedBox(height: 16),

          if (widget.chant.pdfFiles?.isNotEmpty == true || widget.chant.pdfPath != null)
            _buildFileSection(
              title: 'Partitions PDF',
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              files: widget.chant.pdfFiles ?? (widget.chant.pdfPath != null ? [widget.chant.pdfPath!] : []),
            ),

          const SizedBox(height: 16),

          if (widget.chant.imageFiles?.isNotEmpty == true || widget.chant.imagePath != null)
            _buildFileSection(
              title: 'Images',
              icon: Icons.image,
              color: Colors.blue,
              files: widget.chant.imageFiles ?? (widget.chant.imagePath != null ? [widget.chant.imagePath!] : []),
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
                  _buildInfoRow('Ordre', widget.chant.ordre.toString()),
                  _buildInfoRow('Statut', widget.chant.active ? 'Actif' : 'Inactif'),
                  _buildInfoRow('Créé le', _formatDate(widget.chant.createdAt)),
                  _buildInfoRow('Modifié le', _formatDate(widget.chant.updatedAt)),
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
            }).toList(),
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
      // TODO: Implémenter le téléchargement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Téléchargement de $file...'),
          backgroundColor: Colors.blue,
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
        loading = false;
      });
    }
  }

  void _playAudio(String file) {
    // TODO: Implémenter la lecture audio
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lecture de $file...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewPdf(String file) {
    // TODO: Implémenter la visualisation PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de $file...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _viewImage(String file) {
    // TODO: Implémenter la visualisation d'image
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de $file...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _addFiles() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFilesToChantScreen(chant: widget.chant),
      ),
    );
  }

  void _addFilesToPupitre(String pupitreName) {
    // TODO: Implémenter l'ajout de fichiers spécifiques à un pupitre
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ajout de fichiers pour le pupitre $pupitreName...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
