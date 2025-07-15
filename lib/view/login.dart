import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/functions/appconstants.dart';
import 'package:voxbox/models/user.dart';
import 'package:voxbox/services/api_response.dart';
import 'package:voxbox/services/auth_service.dart';
import 'package:voxbox/view/home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController(); // Changé de phoneNumberController
  bool isPasswordFilled = true;
  bool isEmailFilled = true; // Changé de isPhoneNumberFilled
  final TextEditingController controller = TextEditingController();
  String initialCountry = 'ML';
  String phoneNumber = '';
  bool loading = false;

  void loginUser() async {
    setState(() {
      loading = true;
    });
    
    // Utiliser le nouveau service Laravel
    ApiResponse response = await loginWithLaravel(
      emailController.text, 
      passwordController.text
    );
    
    setState(() {
      loading = false;
    });
    
    if (response.error == null && response.data != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Connecté avec succès'),
        backgroundColor: Colors.green
      ));
      _saveAndRedirectToHome(response.data as User);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response.error ?? 'Erreur lors de la connexion'),
        backgroundColor: Colors.red
      ));
    }
  }

  void _saveAndRedirectToHome(User user) async {
    print(user.name.toString());

    Map<String, dynamic> userMap = user.toJson();
    String userJson = jsonEncode(userMap);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('user', userJson);
    prefs.setString('token', AppConstance.token ?? '');
    prefs.setBool('isConnected', true);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, 
            colors: [
              AppConstance.priGradient,
              AppConstance.secondary,
            ]
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 50),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    AppImages.logo,
                    width: 160,
                  ),
                  Text(
                    AppConstance.appName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width / 18
                    ),
                  ),
                  SizedBox(height: 1),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(135),
                  )
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 60),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(8, 34, 105, 0.298),
                                blurRadius: 20,
                                offset: Offset(0, 10)
                              )
                            ]
                          ),
                          child: Container(
                            margin: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(top: 15, bottom: 10),
                                  child: Row(
                                    children: [
                                      Text('* ', style: TextStyle(color: Colors.red)),
                                      Text('Email'), // Changé de 'Numéro de téléphone'
                                    ],
                                  ),
                                ),
                                Container(
                                  child: TextField(
                                    controller: emailController, // Changé
                                    textInputAction: TextInputAction.next,
                                    keyboardType: TextInputType.emailAddress, // Ajouté
                                    onChanged: (text) {
                                      setState(() {
                                        isEmailFilled = text.isNotEmpty; // Changé
                                      });
                                    },
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: 'votre@email.com', // Changé
                                      hintText: 'Saisissez votre email',
                                      labelStyle: TextStyle(fontSize: 18.0),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 15, bottom: 10),
                                  child: Row(
                                    children: [
                                      Text('* ', style: TextStyle(color: Colors.red)),
                                      Text('Mot de passe'), // Changé de 'Code'
                                    ],
                                  ),
                                ),
                                Container(
                                  child: TextField(
                                    controller: passwordController,
                                    textInputAction: TextInputAction.done,
                                    obscureText: true,
                                    onChanged: (text) {
                                      setState(() {
                                        isPasswordFilled = text.isNotEmpty;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      isDense: true,
                                      labelText: '*********',
                                      hintText: 'Saisissez votre mot de passe',
                                      labelStyle: TextStyle(fontSize: 18.0),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ),
                        SizedBox(height: 40),
                        if (loading)
                          SpinKitCircle(
                            color: AppConstance.primary,
                            size: 50.0,
                          ),
                        MaterialButton(
                          onPressed: () async {
                            loginUser();
                          },
                          height: 50,
                          color: AppConstance.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Center(
                            child: Text(
                              "Connexion",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  )
                ),
              )
            )
          ],
        ),
      ),
    );
  }
}
