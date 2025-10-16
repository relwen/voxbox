import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:voxbox/services/vocalise_service.dart';
import 'package:voxbox/services/partition_service.dart';

class AutoSyncService {
  static final AutoSyncService _instance = AutoSyncService._internal();
  factory AutoSyncService() => _instance;
  AutoSyncService._internal();

  Timer? _syncTimer;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isConnected = false;
  bool _isSyncing = false;

  // Configuration
  static const Duration _syncInterval = Duration(minutes: 15); // Synchronisation toutes les 15 minutes
  static const Duration _retryInterval = Duration(minutes: 5); // Retry toutes les 5 minutes en cas d'échec

  // Streams
  final StreamController<bool> _isSyncingController = StreamController<bool>.broadcast();
  final StreamController<String> _syncStatusController = StreamController<String>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  bool get isSyncing => _isSyncing;
  Stream<bool> get isSyncingStream => _isSyncingController.stream;
  Stream<String> get syncStatusStream => _syncStatusController.stream;

  // Initialisation du service
  void initialize() {
    _setupConnectivityListener();
    _startPeriodicSync();
  }

  // Configuration de l'écoute de la connectivité
  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) {
        final wasConnected = _isConnected;
        _isConnected = result != ConnectivityResult.none;

        if (!wasConnected && _isConnected) {
          // Reconnexion détectée - synchronisation immédiate
          _syncStatusController.add('Reconnexion détectée - Synchronisation...');
          _performSync();
        } else if (wasConnected && !_isConnected) {
          // Déconnexion détectée
          _syncStatusController.add('Mode hors ligne');
        }
      },
    );

    // Vérifier l'état initial
    Connectivity().checkConnectivity().then((result) {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  // Démarrer la synchronisation périodique
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      if (_isConnected && !_isSyncing) {
        _performSync();
      }
    });
  }

  // Effectuer la synchronisation
  Future<void> _performSync() async {
    if (_isSyncing || !_isConnected) return;

    _isSyncing = true;
    _isSyncingController.add(true);

    try {
      _syncStatusController.add('Synchronisation des vocalises...');
      
      // Synchroniser les vocalises
      final vocaliseResponse = await VocaliseService.syncVocalises();
      if (vocaliseResponse.error != null) {
        _syncStatusController.add('Erreur vocalises: ${vocaliseResponse.error}');
      } else {
        _syncStatusController.add('Vocalises synchronisées');
      }

      // Les messes sont maintenant gérées par le système unifié de partitions

      // Synchroniser les partitions (inclut les messes, chants, etc.)
      _syncStatusController.add('Synchronisation des partitions...');
      final partitionResponse = await PartitionService.syncPartitions();
      if (partitionResponse.error != null) {
        _syncStatusController.add('Erreur partitions: ${partitionResponse.error}');
      } else {
        _syncStatusController.add('Partitions synchronisées (messes incluses)');
      }

      _syncStatusController.add('Synchronisation terminée');
      
    } catch (e) {
      _syncStatusController.add('Erreur de synchronisation: $e');
      
      // Programmer une nouvelle tentative
      Timer(_retryInterval, () {
        if (_isConnected) {
          _performSync();
        }
      });
    } finally {
      _isSyncing = false;
      _isSyncingController.add(false);
    }
  }

  // Synchronisation manuelle
  Future<void> manualSync() async {
    if (_isSyncing) return;
    
    _syncStatusController.add('Synchronisation manuelle...');
    await _performSync();
  }

  // Synchronisation forcée (ignore l'état de connectivité)
  Future<void> forceSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _isSyncingController.add(true);

    try {
      _syncStatusController.add('Synchronisation forcée...');
      
      // Synchroniser les vocalises
      final vocaliseResponse = await VocaliseService.getVocalises(forceRefresh: true);
      if (vocaliseResponse.error != null) {
        _syncStatusController.add('Erreur vocalises: ${vocaliseResponse.error}');
      } else {
        _syncStatusController.add('Vocalises synchronisées');
      }

      // Les messes sont maintenant gérées par le système unifié de partitions

      // Synchroniser les partitions (inclut les messes, chants, etc.)
      _syncStatusController.add('Synchronisation des partitions...');
      final partitionResponse = await PartitionService.syncPartitions();
      if (partitionResponse.error != null) {
        _syncStatusController.add('Erreur partitions: ${partitionResponse.error}');
      } else {
        _syncStatusController.add('Partitions synchronisées (messes incluses)');
      }

      _syncStatusController.add('Synchronisation forcée terminée');
      
    } catch (e) {
      _syncStatusController.add('Erreur de synchronisation forcée: $e');
    } finally {
      _isSyncing = false;
      _isSyncingController.add(false);
    }
  }

  // Arrêter le service
  void stop() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _isSyncingController.close();
    _syncStatusController.close();
  }

  // Redémarrer le service
  void restart() {
    stop();
    initialize();
  }

  // Obtenir le statut de synchronisation
  Map<String, dynamic> getSyncStatus() {
    return {
      'isConnected': _isConnected,
      'isSyncing': _isSyncing,
      'syncInterval': _syncInterval.inMinutes,
      'retryInterval': _retryInterval.inMinutes,
    };
  }
}
