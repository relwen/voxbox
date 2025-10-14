import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:voxbox/functions/appconstants.dart';

class SyncIndicator extends StatefulWidget {
  final VoidCallback? onSyncPressed;
  
  const SyncIndicator({Key? key, this.onSyncPressed}) : super(key: key);

  @override
  _SyncIndicatorState createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  bool hasInternet = true;
  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _listenToConnectivityChanges();
  }

  void _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      hasInternet = connectivityResult != ConnectivityResult.none;
    });
  }

  void _listenToConnectivityChanges() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        hasInternet = result != ConnectivityResult.none;
      });
    });
  }

  void _handleSync() async {
    if (widget.onSyncPressed != null) {
      setState(() {
        isSyncing = true;
      });
      
      try {
        widget.onSyncPressed?.call();
      } finally {
        setState(() {
          isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInternet) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange,
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mode hors ligne - Données locales disponibles',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppConstance.primary.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            isSyncing ? Icons.sync : Icons.sync_alt,
            color: AppConstance.primary,
            size: 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              isSyncing ? 'Synchronisation en cours...' : 'Connecté - Données à jour',
              style: TextStyle(color: AppConstance.primary, fontSize: 12),
            ),
          ),
          if (widget.onSyncPressed != null && !isSyncing)
            GestureDetector(
              onTap: _handleSync,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppConstance.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Synchroniser',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
