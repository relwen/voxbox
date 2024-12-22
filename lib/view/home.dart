import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/view/actualites/actualites.dart';
import 'package:voxbox/view/chants/chants.dart';
import 'package:voxbox/view/creations/creations.dart';
import 'package:voxbox/view/exercises/exercises.dart';
import 'package:voxbox/view/login.dart';
import 'package:voxbox/view/messes/messes.dart';
import 'package:voxbox/view/vocalize/vocalize.dart';
import 'package:voxbox/widgets/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  Collector collector = Collector();
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Login()),
      (route) => false,
    );
  }

  @override
  void initState() {
    getUser();
    super.initState();
  }

  Future<void> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userString = prefs.getString('user');
    Map<String, dynamic> userMap = jsonDecode(userString!);

    setState(() {
      collector = Collector.fromJson(userMap);
    });
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _logout();
                Navigator.of(context).pop();
              },
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
        children: [
          Stack(
            children: [
              SvgPicture.asset(
                "assets/svg/bg.svg",
                width: MediaQuery.of(context).size.width,
              ),
              const Positioned(
                  top: 50,
                  left: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 60,
                        color: Colors.white,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 5,
                          ),
                          MyText(
                            text: "Relwendé Jacob",
                            size: 14,
                            color: Colors.white,
                            fontweight: FontWeight.bold,
                          ),
                          MyText(
                            text: "Basse",
                            size: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 15,
                      ),
                    ],
                  ))
            ],
          ),
          Container(
            padding: EdgeInsets.all(25),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      "MENU",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      width: 105,
                      height: 8,
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [theme, theme2]),
                          borderRadius: BorderRadius.circular(50)),
                    )
                  ],
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              cardItem(
                  icon: Icons.switch_access_shortcut_add_outlined,
                  title: "Vocalise",
                  context: context,
                  gradient: true,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VocaliseScreen()));
                  }),
              cardItem(
                  icon: Icons.church_outlined,
                  title: "Messes",
                  context: context,
                  gradient: false,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MessesScreen()));
                  }),
              cardItem(
                  icon: Icons.multitrack_audio,
                  title: "Chants",
                  context: context,
                  gradient: true,
                  onTap: () {
                    
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>const ChantsScreen()));
                  }),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              cardItem(
                  icon: Icons.switch_access_shortcut_add_outlined,
                  title: "Créations",
                  context: context,
                  gradient: false,
                  onTap: () {
                    
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>const CreationsScreen()));
                  }),
              cardItem(
                  icon: Icons.queue_music_rounded,
                  title: "Exercices",
                  context: context,
                  gradient: false,
                  onTap: () {
                    
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>const ExercisesScreen()));
                  }),
              cardItem(
                  icon: Icons.my_library_music_outlined,
                  title: "Actualités",
                  context: context,
                  gradient: true,
                  onTap: () {
                    
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>const ActualitesScreen()));
                  }),
            ],
          ),
        ],
      )),
    );
  }
}

Offset calculatePosition(BuildContext context, String text, double iconSize) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: 22, color: Colors.white),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();

  final textWidth = textPainter.width;
  final horizontalPosition =
      (MediaQuery.of(context).size.width - textWidth) / 2;
  final verticalPosition = MediaQuery.of(context).size.height / 4 - iconSize;

  return Offset(horizontalPosition, verticalPosition);
}
