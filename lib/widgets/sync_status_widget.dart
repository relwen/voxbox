import 'dart:async';
import 'package:flutter/material.dart';
import 'package:voxbox/services/auto_sync_service.dart';
import 'package:voxbox/functions/appconstants.dart';

class SyncStatusWidget extends StatefulWidget {
  final bool showDetails;
  final VoidCallback? onSyncPressed;

  const SyncStatusWidget({
    Key? key,
    this.showDetails = false,
    this.onSyncPressed,
  }) : super(key: key);

  @override
  _SyncStatusWidgetState createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final AutoSyncService _syncService = AutoSyncService();
  late StreamSubscription<bool> _isSyncingSubscription;
  late StreamSubscription<String> _syncStatusSubscription;
  
  bool _isSyncing = false;
  String _syncStatus = '';

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _isSyncingSubscription = _syncService.isSyncingStream.listen((isSyncing) {
      if (mounted) {
        setState(() {
          _isSyncing = isSyncing;
        });
      }
    });

    _syncStatusSubscription = _syncService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });
      }
    });
  }

  @override
  void dispose() {
    _isSyncingSubscription.cancel();
    _syncStatusSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSyncing && _syncStatus.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isSyncing ? AppConstance.primary : Colors.green,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône de statut
          if (_isSyncing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 16,
            ),
          
          SizedBox(width: 8),
          
          // Texte de statut
          Expanded(
            child: Text(
              _syncStatus.isNotEmpty ? _syncStatus : 'Synchronisation...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Bouton de synchronisation manuelle
          if (widget.onSyncPressed != null && !_isSyncing)
            TextButton(
              onPressed: widget.onSyncPressed,
              child: Text(
                'Sync',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Widget compact pour la barre d'état
class CompactSyncStatusWidget extends StatefulWidget {
  const CompactSyncStatusWidget({Key? key}) : super(key: key);

  @override
  _CompactSyncStatusWidgetState createState() => _CompactSyncStatusWidgetState();
}

class _CompactSyncStatusWidgetState extends State<CompactSyncStatusWidget> {
  final AutoSyncService _syncService = AutoSyncService();
  late StreamSubscription<bool> _isSyncingSubscription;
  
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _isSyncingSubscription = _syncService.isSyncingStream.listen((isSyncing) {
      if (mounted) {
        setState(() {
          _isSyncing = isSyncing;
        });
      }
    });
  }

  @override
  void dispose() {
    _isSyncingSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSyncing) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstance.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 4),
          Text(
            'Sync',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
