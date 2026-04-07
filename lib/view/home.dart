import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/view/actualites/actualites.dart';
import 'package:voxbox/view/chants/chants.dart';
import 'package:voxbox/view/creations/quick_record_screen.dart';
import 'package:voxbox/view/creations/recordings_list_screen.dart';
import 'package:voxbox/view/exercises/exercises.dart';
import 'package:voxbox/view/messes/messes.dart';
import 'package:voxbox/view/profile.dart';
import 'package:voxbox/view/vocalize/vocalize.dart';
import 'package:voxbox/view/complete_profile_screen.dart';
import 'package:voxbox/view/search_results_screen.dart';
import 'package:voxbox/services/auth_service.dart';
import 'package:voxbox/services/toast_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  User user = User();

  @override
  void initState() {
    getUser();
    super.initState();
  }

  Future<void> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userString = prefs.getString('user');
    if (userString != null) {
      Map<String, dynamic> userMap = jsonDecode(userString);

      setState(() {
        user = User.fromJson(userMap);
      });
      
      // Vérifier si le profil est incomplet (uniquement pour les utilisateurs connectés)
      if (user.id != null && user.isProfileIncomplete()) {
        // Rediriger vers la complétion du profil
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CompleteProfileScreen(user: user),
            ),
          );
        });
      }
    } else {
      // Mode Invité : l'utilisateur n'est pas en cache
      print('ℹ️ Mode Invité activé');
    }
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstance.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppConstance.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Rechercher',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Champ de recherche
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une partition, chant, vocalise...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _performSearch(value);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Bouton de validation
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      debugPrint('🔍 Bouton rechercher cliqué');
                      final query = searchController.text.trim();
                      debugPrint('🔍 Texte de recherche: "$query"');

                      if (query.isEmpty) {
                        debugPrint('⚠️ Recherche vide');
                        ToastService.warning(
                          context,
                          'Veuillez entrer un terme de recherche',
                        );
                        return;
                      }

                      debugPrint('✅ Fermeture du dialog et navigation vers les résultats');
                      Navigator.of(context).pop();

                      // Navigation vers les résultats
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResultsScreen(query: query),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstance.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.search_rounded, size: 20),
                    label: const Text(
                      'Rechercher',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      ToastService.warning(
        context,
        'Veuillez entrer un terme de recherche',
      );
      return;
    }

    // Naviguer vers l'écran des résultats de recherche
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(query: query),
      ),
    );
  }


  void _showLoginRequiredDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: AppConstance.primary),
            const SizedBox(width: 10),
            const Text('Connexion requise'),
          ],
        ),
        content: Text(
          'Veuillez vous connecter pour pouvoir $action. Souhaitez-vous vous connecter maintenant ?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstance.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstance.primary,
              AppConstance.priGradient,
              AppConstance.secondary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Section supérieure avec gradient (header seulement)
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildModernHeader(size),
                    ],
                  ),
                ),
              ),
              // Section inférieure blanche (menu principal)
              Expanded(
                flex: 5,
                child: _buildMenuSection(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuickRecordScreen()),
            );
          },
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          child: const Icon(Icons.mic, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildModernHeader(Size size) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar avec gradient
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)],
              ),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Icon(
              Icons.account_circle,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 15),
          
          // Informations utilisateur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   'Bonjour,',
                //   style: TextStyle(
                //     color: Colors.white.withOpacity(0.8),
                //     fontSize: 14,
                //     fontWeight: FontWeight.w400,
                //   ),
                // ),
                // const SizedBox(height: 2),
                Text(
                  user.id == null ? "Invité" : (user.name ?? "Utilisateur"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.id == null ? "Accès limité" : (user.voicePart ?? "Pupitre non défini"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Boutons d'action
          Row(
            children: [
              // Bouton de recherche
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _showSearchDialog,
                  icon: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Bouton de profil
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    if (user.id == null) {
                      _showLoginRequiredDialog('consulter votre profil');
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  icon: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }




  Widget _buildSelectionDuJour() {
    // Liste des partitions disponibles pour la sélection du jour
    final partitionsDuJour = [
      {'titre': 'Kyrié Eleison', 'icon': Icons.church_rounded, 'color': Colors.blue},
      {'titre': 'Gloria in Excelsis', 'icon': Icons.celebration_rounded, 'color': Colors.green},
      {'titre': 'Ave Maria', 'icon': Icons.favorite_rounded, 'color': Colors.pink},
      {'titre': 'Vocalise N°1', 'icon': Icons.music_note_rounded, 'color': Colors.orange},
      {'titre': 'Sanctus', 'icon': Icons.cloud_queue_rounded, 'color': Colors.purple},
      {'titre': 'Agnus Dei', 'icon': Icons.self_improvement_rounded, 'color': Colors.teal},
    ];

    // Sélection aléatoire basée sur la date du jour
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final random = (seed % partitionsDuJour.length);
    final partitionSelectionnee = partitionsDuJour[random];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (partitionSelectionnee['color'] as Color).withOpacity(0.1),
            (partitionSelectionnee['color'] as Color).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (partitionSelectionnee['color'] as Color).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (partitionSelectionnee['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.today_rounded,
              color: partitionSelectionnee['color'] as Color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélection du Jour',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  partitionSelectionnee['titre'] as String,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Bouton play
          Container(
            decoration: BoxDecoration(
              color: partitionSelectionnee['color'] as Color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () {
                ToastService.info(
                  context,
                  'Ouverture de "${partitionSelectionnee['titre']}"...',
                );
              },
              icon: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du jour
            // _buildSelectionDuJour(),
            // const SizedBox(height: 30),
            
            const Text(
              'Menu Principal',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
          
          // Première ligne
          Row(
            children: [
              _buildModernCard(
                icon: Icons.switch_access_shortcut_add_rounded,
                title: 'Vocalises',
                subtitle: 'Exercices vocaux',
                gradient: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VocaliseScreen()),
                ),
              ),
              _buildModernCard(
                icon: Icons.church_rounded,
                title: 'Messes',
                subtitle: 'Célébrations',
                gradient: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MessesScreen()),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Deuxième ligne
          Row(
            children: [
              if (user.id != null)
                _buildModernCard(
                  icon: Icons.multitrack_audio_rounded,
                  title: 'Chants',
                  subtitle: 'Répertoire',
                  gradient: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChantsScreen()),
                  ),
                ),
              _buildModernCard(
                icon: Icons.create_rounded,
                title: 'Créations',
                subtitle: 'Compositions',
                gradient: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecordingsListScreen()),
                ),
              ),
              if (user.id == null) const Spacer(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Troisième ligne
          // Row(
          //   children: [
          //     _buildModernCard(
          //       icon: Icons.fitness_center_rounded,
          //       title: 'Exercices',
          //       subtitle: 'Entraînement',
          //       gradient: false,
          //       onTap: () => Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (_) => const ExercisesScreen()),
          //       ),
          //     ),
          //     _buildModernCard(
          //       icon: Icons.newspaper_rounded,
          //       title: 'Actualités',
          //       subtitle: 'Dernières infos',
          //       gradient: true,
          //       onTap: () => Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (_) => const ActualitesScreen()),
          //       ),
          //     ),
          //   ],
          // ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool gradient,
    required VoidCallback onTap,
  }) {
    // Couleurs d'accent pour chaque type de card
    Color accentColor = gradient ? AppConstance.primary : Colors.grey.shade600;
    
    // Tailles dynamiques basées sur MediaQuery
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculer les tailles en fonction de l'écran
    final cardHeight = screenWidth * 0.34; // 18% de la hauteur d'écran
    final iconSize = screenWidth * 0.10; // 12% de la largeur d'écran
    final iconContainerSize = screenWidth * 0.13; // 13% de la largeur d'écran
    final fontSize = screenWidth * 0.032; // 3.2% de la largeur d'écran
    final subtitleFontSize = screenWidth * 0.025; // 2.5% de la largeur d'écran
    final padding = screenWidth * 0.02; // 4% de la largeur d'écran
    final margin = screenWidth * 0.01; // 1% de la largeur d'écran
    final borderRadius = screenWidth * 0.05; // 5% de la largeur d'écran
    
    return Expanded(
      child: Container(
        height: cardHeight,
        margin: EdgeInsets.symmetric(horizontal: margin, vertical: margin),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: gradient ? AppConstance.primary.withOpacity(0.2) : Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient 
                  ? AppConstance.primary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône avec gradient
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      gradient: gradient
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor.withOpacity(0.1),
                                accentColor.withOpacity(0.05),
                              ],
                            )
                          : null,
                      color: gradient ? null : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(borderRadius * 0.75),
                      border: Border.all(
                        color: accentColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.012), // 1.2% de la hauteur d'écran
                  
                  // Titre
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.005), // 0.5% de la hauteur d'écran
                  
                  // Sous-titre
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Indicateur de gradient (petit point)
                  if (gradient) ...[
                    SizedBox(height: screenHeight * 0.007), // 0.7% de la hauteur d'écran
                    Container(
                      width: screenWidth * 0.015, // 1.5% de la largeur d'écran
                      height: screenWidth * 0.015, // 1.5% de la largeur d'écran
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

Offset calculatePosition(BuildContext context, String text, double iconSize) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: 22, color: Colors.white),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();

  final textWidth = textPainter.width;
  final horizontalPosition =
      (MediaQuery.of(context).size.width - textWidth) / 2;
  final verticalPosition = MediaQuery.of(context).size.height / 4 - iconSize;

  return Offset(horizontalPosition, verticalPosition);
}
