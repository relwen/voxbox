import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/widgets/widgets.dart';
import 'package:voxbox/models/messe.dart';
import 'package:voxbox/services/messe_service.dart';
import 'package:voxbox/services/toast_service.dart';
import 'package:voxbox/view/messes/messe_sections.dart';
import 'package:voxbox/widgets/offline_indicator.dart';
import 'package:voxbox/widgets/shimmer_loading.dart';

class MessesScreen extends StatefulWidget {
  const MessesScreen({super.key});

  @override
  State<MessesScreen> createState() => _MessesScreenState();
}

class _MessesScreenState extends State<MessesScreen> {
  List<Messe> messes = [];
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
      // Charger les messes depuis le serveur
      var messeResponse = await MesseService.getMessessFromServer();
      if (messeResponse.error == null) {
        setState(() {
          messes = messeResponse.data as List<Messe>;
          loading = false;
        });
      } else {
        // En cas d'erreur, charger depuis le stockage local
        List<Messe> localMessess = await MesseService.getLocalMessess();
        setState(() {
          messes = localMessess;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  void _syncMesses() async {
    setState(() {
      syncing = true;
    });

    try {
      var response = await MesseService.syncMessess();
      if (response.error == null) {
        setState(() {
          messes = response.data!;
        });
        ToastService.success(
          context,
          'Messes synchronisées avec succès',
        );
      } else {
        ToastService.error(
          context,
          'Erreur de synchronisation: ${response.error}',
        );
      }
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

  IconData _getIconForMesse(String messeName) {
    String name = messeName.toLowerCase();
    if (name.contains('st gabriel')) return Icons.church;
    if (name.contains('sympathie')) return Icons.favorite;
    if (name.contains('pentecote')) return Icons.celebration;
    if (name.contains('dominicale')) return Icons.self_improvement;
    return Icons.music_note;
  }

  void _openMesse(Messe messe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MesseSectionsScreen(messe: messe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MyText(
          text: 'Mes Messes',
          color: Colors.white,
          size: 20,
          fontweight: FontWeight.bold,
        ),
        backgroundColor: AppConstance.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: syncing ? null : _syncMesses,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: loading
                ? const ShimmerListLoading()
                : messes.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.church,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucune messe trouvée',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Appuyez sur le bouton de synchronisation pour charger les messes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messes.length,
                        itemBuilder: (context, index) {
                          Messe messe = messes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 4,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(int.parse(messe.couleur.replaceAll('#', '0xFF'))),
                                child: Icon(
                                  _getIconForMesse(messe.nom),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                messe.nom,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (messe.description != null)
                                    Text(
                                      messe.description!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${messe.sections?.length ?? 0} section${(messe.sections?.length ?? 0) > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () => _openMesse(messe),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _syncMesses,
        backgroundColor: AppConstance.primary,
        child: syncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.sync, color: Colors.white),
      ),
    );
  }
}