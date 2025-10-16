import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/view/actualites/actualites.dart';
import 'package:voxbox/view/chants/chants.dart';
import 'package:voxbox/view/creations/creations.dart';
import 'package:voxbox/view/exercises/exercises.dart';
import 'package:voxbox/view/login.dart';
import 'package:voxbox/view/messes/messes.dart';
import 'package:voxbox/view/vocalize/vocalize.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  User user = User();
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    await prefs.setBool('isConnected', false);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

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
    }
  }

  void _showSearchDialog() {
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
                    onChanged: (value) {
                      // TODO: Implémenter la recherche en temps réel
                    },
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _performSearch(value);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Suggestions de recherche
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggestions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSearchSuggestion('Kyrié'),
                        _buildSearchSuggestion('Gloria'),
                        _buildSearchSuggestion('Ave Maria'),
                        _buildSearchSuggestion('Vocalises'),
                        _buildSearchSuggestion('Chants'),
                        _buildSearchSuggestion('Messes'),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Bouton de recherche
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implémenter la recherche
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité de recherche en cours de développement'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstance.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Rechercher',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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

  Widget _buildSearchSuggestion(String suggestion) {
    return GestureDetector(
      onTap: () {
        _performSearch(suggestion);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppConstance.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstance.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            color: AppConstance.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _performSearch(String query) {
    // TODO: Implémenter la logique de recherche
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recherche pour: "$query"'),
        backgroundColor: AppConstance.primary,
        action: SnackBarAction(
          label: 'Voir résultats',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Naviguer vers les résultats de recherche
          },
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                // Icône
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Titre
                const Text(
                  'Déconnexion',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Message
                Text(
                  'Êtes-vous sûr de vouloir vous déconnecter ?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _logout();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Déconnexion',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
                Text(
                  'Bonjour,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.name ?? "Utilisateur",
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
                    user.voicePart ?? "Pupitre non défini",
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
              
              // Bouton de déconnexion
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _showLogoutConfirmationDialog,
                  icon: const Icon(
                    Icons.logout_rounded,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ouverture de "${partitionSelectionnee['titre']}"...'),
                    backgroundColor: partitionSelectionnee['color'] as Color,
                  ),
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
            _buildSelectionDuJour(),
            const SizedBox(height: 30),
            
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
                  MaterialPageRoute(builder: (_) => const CreationsScreen()),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Troisième ligne
          Row(
            children: [
              _buildModernCard(
                icon: Icons.fitness_center_rounded,
                title: 'Exercices',
                subtitle: 'Entraînement',
                gradient: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExercisesScreen()),
                ),
              ),
              _buildModernCard(
                icon: Icons.newspaper_rounded,
                title: 'Actualités',
                subtitle: 'Dernières infos',
                gradient: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActualitesScreen()),
                ),
              ),
            ],
          ),
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
    
    return Expanded(
      child: Container(
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône avec gradient
                  Container(
                    width: 50,
                    height: 50,
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
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: accentColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Titre
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Sous-titre
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Indicateur de gradient (petit point)
                  if (gradient) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 6,
                      height: 6,
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
