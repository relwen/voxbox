import 'package:flutter/material.dart';
import 'package:voxbox/services/global_recorder_service.dart';
import 'package:voxbox/services/global_audio_player_service.dart';
import 'package:voxbox/widgets/floating_recorder_widget.dart';
import 'package:voxbox/widgets/floating_audio_player_widget.dart';

/// Wrapper pour l'application qui affiche les widgets flottants (enregistrement et lecteur audio)
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
  final GlobalAudioPlayerService _audioPlayerService = GlobalAudioPlayerService();

  @override
  void initState() {
    super.initState();
    _recorderService.initialize();
    _audioPlayerService.initialize();
  }

  @override
  void dispose() {
    _recorderService.dispose();
    _audioPlayerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the child MaterialApp with a builder to inject the floating widgets
    return widget.child is MaterialApp
        ? MaterialApp(
            debugShowCheckedModeBanner: (widget.child as MaterialApp).debugShowCheckedModeBanner,
            title: (widget.child as MaterialApp).title ?? '',
            theme: (widget.child as MaterialApp).theme,
            builder: (context, child) {
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  FloatingRecorderWidget(recorderService: _recorderService),
                  FloatingAudioPlayerWidget(playerService: _audioPlayerService),
                ],
              );
            },
            home: (widget.child as MaterialApp).home,
          )
        : Stack(
            children: [
              widget.child,
              FloatingRecorderWidget(recorderService: _recorderService),
              FloatingAudioPlayerWidget(playerService: _audioPlayerService),
            ],
          );
  }
}
