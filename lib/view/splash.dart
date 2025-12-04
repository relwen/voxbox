import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/view/home.dart';
import 'package:voxbox/view/login.dart';
import 'package:voxbox/view/complete_profile_screen.dart';
import 'package:voxbox/view/pending_approval_screen.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/vocalise_service.dart';
import 'package:voxbox/services/auto_sync_service.dart';
import 'package:voxbox/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      const Duration(seconds: 1),
      () {
        checkisConnected();
      },
    );
  }

  void checkisConnected() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isConnected = prefs.getBool('isConnected') ?? false;

    if (isConnected) {
      // Toujours récupérer les données utilisateur depuis l'API au démarrage
      // pour avoir les données à jour (notamment le statut)
      User? user;
      
      try {
        print('🔄 Récupération des données utilisateur depuis l\'API...');
        final response = await getUserInfo();
        if (response.error == null && response.data != null) {
          user = response.data as User;
          // Mettre à jour le cache avec les données fraîches
          await prefs.setString('user', jsonEncode(user.toJson()));
          print('✅ Données utilisateur mises à jour depuis l\'API');
          print('   - Status: ${user.status}');
          print('   - Nom: ${user.name ?? "VIDE"}');
          print('   - Chorale ID: ${user.choraleId ?? "VIDE"}');
        } else {
          print('⚠️ Erreur lors de la récupération depuis l\'API: ${response.error}');
          // En cas d'erreur API, utiliser le cache comme fallback
          String? userString = prefs.getString('user');
          if (userString != null) {
            try {
              Map<String, dynamic> userMap = jsonDecode(userString);
              user = User.fromJson(userMap);
              print('📦 Utilisation des données en cache (fallback)');
            } catch (e) {
              print('Erreur de parsing utilisateur depuis le cache: $e');
            }
          }
        }
      } catch (e) {
        print('💥 Exception lors de la récupération de l\'utilisateur: $e');
        // En cas d'exception, utiliser le cache comme fallback
        String? userString = prefs.getString('user');
        if (userString != null) {
          try {
            Map<String, dynamic> userMap = jsonDecode(userString);
            user = User.fromJson(userMap);
            print('📦 Utilisation des données en cache (fallback après exception)');
          } catch (parseError) {
            print('Erreur de parsing utilisateur depuis le cache: $parseError');
          }
        }
      }
      
      if (user == null) {
        // Pas d'utilisateur - rediriger vers la connexion
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
        return;
      }

      // À ce point, user n'est plus null, on peut l'utiliser directement
      final currentUser = user!;

      // Vérifier explicitement que tous les champs requis sont remplis
      // Nom, Chorale et Pupitre doivent être présents avant de vérifier le statut
      bool isNameEmpty = currentUser.name == null || currentUser.name!.trim().isEmpty;
      bool isVoicePartEmpty = currentUser.voicePart == null || currentUser.voicePart!.trim().isEmpty;
      bool isChoraleIdEmpty = currentUser.choraleId == null;
      
      bool needsProfileCompletion = isNameEmpty || isVoicePartEmpty || isChoraleIdEmpty;
      
      if (needsProfileCompletion) {
        // Profil incomplet - rediriger vers la complétion
        // L'utilisateur doit compléter son profil (nom, chorale, pupitre) avant de vérifier le statut
        print('📋 Profil incomplet détecté au démarrage - Redirection vers complétion');
        print('   - Nom: ${currentUser.name ?? "VIDE"}');
        print('   - Voice Part: ${currentUser.voicePart ?? "VIDE"}');
        print('   - Chorale ID: ${currentUser.choraleId ?? "VIDE"}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CompleteProfileScreen(user: currentUser),
          ),
        );
        return;
      }

      // Le profil est complètement rempli (nom, chorale, pupitre), maintenant vérifier le statut
      if (currentUser.status == 'pending') {
        // Statut pending - afficher l'écran d'attente
        print('⏳ Profil complet mais statut pending au démarrage - Affichage de l\'écran d\'attente');
        print('   - Status: ${currentUser.status}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PendingApprovalScreen(),
          ),
        );
      } else {
        // Profil complet et approuvé - synchroniser et rediriger vers l'accueil
        print('👤 Profil complet et approuvé au démarrage - Redirection vers HomePage');
        print('   - Status: ${currentUser.status}');
        _syncVocalisesInBackground();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }

  void _syncVocalisesInBackground() async {
    try {
      // Initialiser le service de synchronisation automatique
      AutoSyncService().initialize();
      
      // Synchronisation silencieuse des vocalises
      await VocaliseService.syncVocalises();
    } catch (e) {
      // Ignorer les erreurs de synchronisation en arrière-plan
      print('Erreur de synchronisation des vocalises: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              child: Image.asset(
                AppImages.logo,
                width: 200,
              ),
            ),
            SpinKitCircle(
              color: AppConstance.primary,
              size: 50.0,
            ),
          ],
        ),
      ),
    );
  }
}
