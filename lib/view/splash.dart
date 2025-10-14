import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/view/home.dart';
import 'package:voxbox/view/login.dart';
import 'package:voxbox/services/vocalise_service.dart';

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
      // Synchroniser les vocalises en arrière-plan si l'utilisateur est connecté
      _syncVocalisesInBackground();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }

  void _syncVocalisesInBackground() async {
    try {
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
