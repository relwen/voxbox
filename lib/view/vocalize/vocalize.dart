import 'package:flutter/material.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/services/vocalise_service.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  void _downloadAudio(Vocalise vocalise) async {
    if (vocalise.isDownloaded) {
      // Supprimer le fichier téléchargé
      bool deleted = await VocaliseService.deleteDownloadedAudio(vocalise);
      if (deleted) {
        setState(() {
          int index = vocalises.indexWhere((v) => v.id == vocalise.id);
          if (index != -1) {
            vocalises[index] = vocalise.copyWith(
              isDownloaded: false,
              localAudioPath: null,
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fichier audio supprimé')),
        );
      }
    } else {
      // Télécharger le fichier
      bool downloaded = await VocaliseService.downloadAudio(vocalise);
      if (downloaded) {
        setState(() {
          int index = vocalises.indexWhere((v) => v.id == vocalise.id);
          if (index != -1) {
            vocalises[index] = vocalise.copyWith(
              isDownloaded: true,
              localAudioPath: 'local_path', // Le service gère le chemin
            );
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fichier audio téléchargé')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du téléchargement')),
        );
      }
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
            icon: Icon(Icons.refresh),
            onPressed: hasInternet ? _refreshVocalises : null,
          ),
        ],
      ),
      body: Column(
        children: [
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

  Widget _buildVocaliseCard(Vocalise vocalise) {
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
              Text(vocalise.description!),
            SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    vocalise.voicePart,
                    style: TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppConstance.primary.withOpacity(0.1),
                ),
                SizedBox(width: 8),
                if (vocalise.choraleName != null)
                  Chip(
                    label: Text(
                      vocalise.choraleName!,
                      style: TextStyle(fontSize: 12),
                    ),
                    backgroundColor: AppConstance.secondary.withOpacity(0.1),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (vocalise.audioPath != null || vocalise.audioUrl != null)
              IconButton(
                icon: Icon(
                  vocalise.isDownloaded ? Icons.delete : Icons.download,
                  color: vocalise.isDownloaded ? Colors.red : AppConstance.primary,
                ),
                onPressed: () => _downloadAudio(vocalise),
                tooltip: vocalise.isDownloaded ? 'Supprimer' : 'Télécharger',
              ),
            IconButton(
              icon: Icon(Icons.play_arrow, color: AppConstance.primary),
              onPressed: () {
                // TODO: Implémenter la lecture audio
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lecture audio à implémenter')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
