import 'package:flutter/material.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/services/vocalise_service.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:voxbox/view/vocalize/add_vocalise.dart';
import 'package:voxbox/view/vocalize/vocalise_details.dart';
import 'package:voxbox/widgets/sync_status_widget.dart';

class VocaliseScreen extends StatefulWidget {
  const VocaliseScreen({super.key});

  @override
  State<VocaliseScreen> createState() => _VocaliseScreenState();
}

class _VocaliseScreenState extends State<VocaliseScreen> {
  List<Vocalise> vocalises = [];
  bool isLoading = true;
  bool hasInternet = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVocalises();
    _checkConnectivity();
  }

  void _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      hasInternet = connectivityResult != ConnectivityResult.none;
    });
  }

  void _loadVocalises() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var response = await VocaliseService.getVocalises();
      if (response.error == null) {
        setState(() {
          vocalises = response.data as List<Vocalise>;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.error;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des vocalises';
        isLoading = false;
      });
    }
  }

  void _refreshVocalises() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var response = await VocaliseService.getVocalises(forceRefresh: true);
      if (response.error == null) {
        setState(() {
          vocalises = response.data as List<Vocalise>;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vocalises synchronisées avec succès')),
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


  void _addVocalise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddVocaliseScreen()),
    );
    
    if (result == true) {
      // Rafraîchir la liste après ajout
      _refreshVocalises();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText(
          text: "Vocalises",
          size: 20,
          color: Colors.white,
          fontweight: FontWeight.w800,
        ),
        foregroundColor: Colors.white,
        backgroundColor: theme,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addVocalise,
            tooltip: 'Ajouter une vocalise',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: hasInternet ? _refreshVocalises : null,
            tooltip: 'Synchroniser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur de synchronisation
          SyncStatusWidget(
            onSyncPressed: hasInternet ? _refreshVocalises : null,
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
                              onPressed: _loadVocalises,
                              child: Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : vocalises.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_note, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Aucune vocalise disponible',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                if (hasInternet) ...[
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _refreshVocalises,
                                    child: Text('Synchroniser'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: vocalises.length,
                            padding: const EdgeInsets.only(top: 8),
                            itemBuilder: (context, index) {
                              final vocalise = vocalises[index];
                              return _buildVocaliseCard(vocalise);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _openVocaliseDetails(Vocalise vocalise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VocaliseDetailsScreen(vocalise: vocalise),
      ),
    );
  }

  Widget _buildVocaliseCard(Vocalise vocalise) {
    // Compter le nombre de fichiers
    int fileCount = 0;
    if (vocalise.audioFiles != null) fileCount += vocalise.audioFiles!.length;
    if (vocalise.pdfFiles != null) fileCount += vocalise.pdfFiles!.length;
    if (vocalise.imageFiles != null) fileCount += vocalise.imageFiles!.length;
    if (vocalise.sopranoFiles != null) fileCount += vocalise.sopranoFiles!.length;
    if (vocalise.altoFiles != null) fileCount += vocalise.altoFiles!.length;
    if (vocalise.tenorFiles != null) fileCount += vocalise.tenorFiles!.length;
    if (vocalise.basseFiles != null) fileCount += vocalise.basseFiles!.length;
    if (vocalise.tuttiFiles != null) fileCount += vocalise.tuttiFiles!.length;

    // Fichiers uniques (legacy)
    if (fileCount == 0) {
      if (vocalise.audioPath != null) fileCount++;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstance.primary,
          child: Icon(
            Icons.music_note,
            color: Colors.white,
          ),
        ),
        title: Text(
          vocalise.title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vocalise.description != null)
              Text(
                vocalise.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    vocalise.voicePart,
                    style: TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppConstance.primary.withValues(alpha: 0.1),
                ),
                SizedBox(width: 8),
                if (fileCount > 0)
                  Chip(
                    label: Text(
                      '$fileCount fichier${fileCount > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _openVocaliseDetails(vocalise),
      ),
    );
  }
}
