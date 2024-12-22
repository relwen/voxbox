import 'package:flutter/material.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/widgets/widgets.dart';

class VocaliseScreen extends StatefulWidget {
  const VocaliseScreen({super.key});

  @override
  State<VocaliseScreen> createState() => _VocaliseScreenState();
}

class _VocaliseScreenState extends State<VocaliseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: "Vocalise",color: theme),
      body: const SingleChildScrollView(
        child: Column(
          
        ),
      ),
    );
  }
}