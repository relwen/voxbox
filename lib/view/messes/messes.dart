import 'package:flutter/material.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/widgets/widgets.dart';

class MessesScreen extends StatefulWidget {
  const MessesScreen({super.key});

  @override
  State<MessesScreen> createState() => _MessesScreenState();
}

class _MessesScreenState extends State<MessesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: "Messes",color: theme),
      body: const SingleChildScrollView(
        child: Column(
          
        ),
      ),
    );
  }
}