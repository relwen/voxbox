import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/view/home.dart';
import 'package:voxbox/view/login.dart';
import 'package:voxbox/view/complete_profile_screen.dart';
import 'package:voxbox/view/pending_approval_screen.dart';
import 'package:voxbox/view/update_required_screen.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/vocalise_service.dart';
import 'package:voxbox/services/auto_sync_service.dart';
import 'package:voxbox/services/auth_service.dart';
import 'package:voxbox/services/version_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool loading = false;
  late AnimationController _logoController;
  late AnimationController _gradientController;
  late AnimationController _waveController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Animation du logo (scale + fade)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    // Animation du gradient
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _gradientController,
        curve: Curves.easeInOut,
      ),
    );

    // Animation des ondes
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Démarrer les animations
    _logoController.forward();

    // Vérifier la connexion après un délai
    Future.delayed(
      const Duration(seconds: 1),
      () {
        checkisConnected();
      },
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _gradientController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void checkisConnected() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Vérifier d'abord si une mise à jour est requise (pour tous les utilisateurs, connectés ou non)
    try {
      print('🔍 Vérification de la version de l\'application...');
      final versionResponse = await VersionService.checkForUpdate();

      if (versionResponse.error == null && versionResponse.data != null) {
        final versionInfo = versionResponse.data!;

        // Si une mise à jour est disponible (version backend > version app)
        if (versionInfo.updateAvailable || versionInfo.updateRequired) {
          print('⚠️ Mise à jour détectée');
          print('   - Version actuelle (app): ${versionInfo.currentVersion}');
          print('   - Dernière version (backend): ${versionInfo.latestVersion}');
          print('   - Mise à jour requise: ${versionInfo.updateRequired}');
          print('   - Mise à jour disponible: ${versionInfo.updateAvailable}');
          
          // Si la version backend est supérieure à la version de l'app, afficher l'écran de mise à jour
          // On affiche toujours l'écran si updateAvailable est true (version backend > version app)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UpdateRequiredScreen(
                currentVersion: versionInfo.currentVersion,
                latestVersion: versionInfo.latestVersion,
                downloadUrl: versionInfo.downloadUrl,
                message: versionInfo.message,
                forceUpdate: versionInfo.forceUpdate || versionInfo.updateRequired,
              ),
            ),
          );
          return;
        } else {
          print('✅ Version de l\'application à jour');
        }
      } else {
        print('⚠️ Impossible de vérifier la version: ${versionResponse.error}');
        // Continuer même si la vérification échoue
      }
    } catch (e) {
      print('💥 Erreur lors de la vérification de version: $e');
      // Continuer même en cas d'erreur de vérification
    }

    // Maintenant vérifier si l'utilisateur est connecté
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
      final currentUser = user;

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _gradientController,
          _waveController,
        ]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    AppConstance.primary,
                    AppConstance.priGradient,
                    _gradientAnimation.value,
                  )!,
                  Color.lerp(
                    AppConstance.priGradient,
                    AppConstance.secondary,
                    _gradientAnimation.value,
                  )!,
                  Color.lerp(
                    AppConstance.secondary,
                    AppConstance.primary,
                    _gradientAnimation.value,
                  )!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Ondes animées en arrière-plan
                ...List.generate(3, (index) {
                  return Positioned(
                    bottom: -50 - (index * 100),
                    left: 0,
                    right: 0,
                    child: CustomPaint(
                      size: Size(size.width, 200),
                      painter: WavePainter(
                        animationValue: (_waveController.value + (index * 0.3)) % 1.0,
                        color: Colors.white.withOpacity(0.1 - (index * 0.03)),
                      ),
                    ),
                  );
                }),

                // Contenu principal
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo avec animations
                      FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              AppImages.logo,
                              width: 180,
                              height: 180,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Nom de l'application avec animation
                      FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Text(
                          AppConstance.appName,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Indicateur de chargement moderne
                      FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: Container(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Cercle de progression animé
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.8),
                                  ),
                                  strokeWidth: 3,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              // Spinner au centre
                              SpinKitPulse(
                                color: Colors.white,
                                size: 30.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Particules flottantes
                ...List.generate(8, (index) {
                  final delay = index * 0.2;
                  final animationValue = (_gradientController.value + delay) % 1.0;
                  return Positioned(
                    left: (size.width / 8) * index,
                    top: size.height * (0.2 + (animationValue * 0.6)),
                    child: Opacity(
                      opacity: (math.sin(animationValue * math.pi * 2) * 0.5 + 0.5) * 0.6,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Peintre personnalisé pour les ondes animées
class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  WavePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 30.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 +
          waveHeight *
              math.sin((x / waveLength + animationValue * 2 * math.pi) * 2 * math.pi);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
