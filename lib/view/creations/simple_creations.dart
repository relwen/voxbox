import 'package:flutter/material.dart';
import 'package:voxbox/services/global_recorder_service.dart';
import 'package:voxbox/services/audio_recorder_service.dart';
import 'package:voxbox/widgets/voice_recorder_button.dart';
import 'package:voxbox/view/creations/recordings_history_sheet.dart';
import 'package:voxbox/view/creations/folders_screen.dart';
import 'package:voxbox/functions/appconstants.dart';

/// Page Créations simplifiée avec enregistrement intuitif
class SimpleCreationsScreen extends StatefulWidget {
  const SimpleCreationsScreen({super.key});

  @override
  State<SimpleCreationsScreen> createState() => _SimpleCreationsScreenState();
}

class _SimpleCreationsScreenState extends State<SimpleCreationsScreen> {
  final GlobalRecorderService _recorderService = GlobalRecorderService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConstance.primary,
                AppConstance.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
            ),
            title: const Text(
              'Créations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Bouton Mes dossiers
              IconButton(
                icon: const Icon(Icons.folder_open, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FoldersScreen()),
                  );
                },
                tooltip: 'Mes dossiers',
              ),
              // Badge d'enregistrements
              FutureBuilder<List<AudioRecording>>(
                future: _recorderService.getRecordings(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.audiotrack, color: Colors.white),
                          onPressed: () {},
                          tooltip: '${snapshot.data!.length} enregistrement(s)',
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${snapshot.data!.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
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
        child: Column(
          children: [
            // Zone principale
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône et instructions
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white70,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Enregistrement rapide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Maintenez le bouton pour enregistrer\nGlissez vers le haut pour verrouiller',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Bouton d'enregistrement
                    VoiceRecorderButton(
                      onRecordingComplete: () {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enregistrement sauvegardé'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Liste des enregistrements récents
            FutureBuilder<List<AudioRecording>>(
              future: _recorderService.getRecordings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Erreur: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final recordings = snapshot.data ?? [];

                if (recordings.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      'Aucun enregistrement pour le moment',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                // Afficher les 3 derniers enregistrements
                final recentRecordings = recordings.take(3).toList();

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: const Text(
                              'Enregistrements récents',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recordings.length > 3)
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      appBar: AppBar(
                                        title: const Text('Tous les enregistrements'),
                                        backgroundColor: AppConstance.primary,
                                      ),
                                      body: RecordingsHistorySheet(
                                        scrollController: ScrollController(),
                                        onClose: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Voir tout'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...recentRecordings.map((recording) => _buildRecordingTile(recording)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingTile(AudioRecording recording) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstance.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.music_note,
              color: AppConstance.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recording.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(recording.duration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            onPressed: () {
              // TODO: Jouer l'enregistrement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lecture en cours de développement'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
