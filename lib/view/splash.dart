import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/view/home.dart';
import 'package:voxbox/view/login.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(seconds: 3),
      () {
        checkisConnected();
      },
    );
  }

  void checkisConnected() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isConnected = prefs.getBool('isConnected') ?? false;

    if (isConnected) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              child: Image.asset(
                AppImages.logo,
                width: 200,
              ),
            ),
            SpinKitCircle(
              color: AppConstance.primary,
              size: 50.0,
            ),
          ],
        ),
      ),
    );
  }
}
