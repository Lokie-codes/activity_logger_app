import 'package:flutter/material.dart';
import 'package:logit_app/login_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Login Calendar App",
      theme: ThemeData(primaryColor: Colors.blue),
      home: Scaffold(
        body: const LoginScreen()
      ),
    );
  }
}
