import 'package:flutter/material.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/widgets/widgets.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(title: "Exercises",color: theme),
      body: const SingleChildScrollView(
        child: Column(
          
        ),
      ),
    );
  }
}