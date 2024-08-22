import 'package:flutter/material.dart';
import 'package:voxbox/view/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SIRD',
        theme: ThemeData(
          hoverColor: Color.fromARGB(255, 11, 50, 95),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 11, 50, 95),
          ),
          useMaterial3: true,
        ),
        home: SplashScreen());
  }
}
