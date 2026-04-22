import 'package:flutter/material.dart';
import 'package:voxbox/view/splash.dart';
import 'package:voxbox/widgets/app_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:voxbox/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    
    // Gérer les messages en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialiser le service de notification
    await NotificationService().initialize();
  } catch (e) {
    print('Erreur lors de l\'initialisation de Firebase: $e');
    print('Note: Assurez-vous d\'avoir ajouté google-services.json (Android) ou GoogleService-Info.plist (iOS)');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VoXY',
        theme: ThemeData(
          hoverColor: const Color.fromARGB(255, 11, 50, 95),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 11, 50, 95),
          ),
          useMaterial3: true,
        ),
        home: SplashScreen(),
      ),
    );
  }
}
