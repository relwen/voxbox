import 'package:flutter/material.dart';
import 'package:voxbox/services/global_recorder_service.dart';
import 'package:voxbox/widgets/floating_recorder_widget.dart';

/// Wrapper pour l'application qui affiche le widget flottant d'enregistrement
class AppWrapper extends StatefulWidget {
  final Widget child;

  const AppWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final GlobalRecorderService _recorderService = GlobalRecorderService();

  @override
  void initState() {
    super.initState();
    _recorderService.initialize();
  }

  @override
  void dispose() {
    _recorderService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        FloatingRecorderWidget(recorderService: _recorderService),
      ],
    );
  }
}
