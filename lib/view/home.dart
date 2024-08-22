import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/view/login.dart';

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
              Positioned(
                  top:
                      calculatePosition(context, collector.name.toString(), 100)
                          .dy,
                  left:
                      calculatePosition(context, collector.name.toString(), 100)
                          .dx,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_circle,
                        size: 100,
                        color: Colors.white,
                      ),
                      Text(
                        collector.name.toString(),
                        style: TextStyle(fontSize: 22, color: Colors.white),
                      )
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
                    Text(
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
                              colors: [
                                Color.fromARGB(255, 2, 59, 31),
                                Colors.green
                              ]),
                          borderRadius: BorderRadius.circular(50)),
                    )
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              cardItem(Icons.woman, "Femmes", context, () {
                // Navigator.of(context)
                //     .push(MaterialPageRoute(builder: (_) => WomanForm()));
              }),
              cardItem(Icons.groups_2_outlined, "OSC", context, () {
                // Navigator.of(context)
                //     .push(MaterialPageRoute(builder: (_) => OSCForm()));
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

Widget cardItem(icon, title, context, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(15),
    child: Card(
      elevation: 10,
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.fromARGB(255, 2, 59, 31), Colors.green])),
        width: MediaQuery.of(context).size.width - 50,
        height: 125,
        padding: EdgeInsets.all(15),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Icon(
            icon,
            size: MediaQuery.of(context).size.width / 5,
            color: Colors.white,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 55,
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Inscription",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 25,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
          )
        ]),
      ),
    ),
  );
}
