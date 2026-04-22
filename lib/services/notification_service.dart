import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:voxbox/functions/appconstants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Canal pour Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications importantes',
    description: 'Ce canal est utilisé pour les notifications importantes.',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialiser Firebase (doit être fait avant d'accéder à FirebaseMessaging)
    // Note: Firebase.initializeApp() doit être appelé dans main.dart

    // Demander la permission (iOS / Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permission de notification accordée');
    } else {
      print('❌ Permission de notification refusée');
    }

    // Configuration des notifications locales pour le premier plan
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gérer le clic sur la notification
        print('Notification cliquée: ${response.payload}');
      },
    );

    // Créer le canal Android
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Écouter les messages au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message reçu au premier plan: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Gérer l'ouverture de l'app via une notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App ouverte via notification: ${message.notification?.title}');
    });

    _isInitialized = true;
    
    // Récupérer et envoyer le token au serveur
    await updateTokenOnServer();
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Erreur lors de la récupération du token FCM: $e');
      return null;
    }
  }

  Future<void> updateTokenOnServer() async {
    final token = await getToken();
    if (token == null) return;

    print('FCM Token: $token');

    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('token');

    if (authToken == null) {
      print('Utilisateur non connecté, token non envoyé au serveur');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${AppConstance.baseURL}/api/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM mis à jour sur le serveur');
      } else {
        print('❌ Erreur lors de la mise à jour du token FCM: ${response.body}');
      }
    } catch (e) {
      print('Erreur réseau lors de la mise à jour du token FCM: $e');
    }
  }
}

// Fonction globale pour gérer les messages en arrière-plan
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Appel de fond: ${message.messageId}');
}
