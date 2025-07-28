import 'package:emregalerimobile/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:emregalerimobile/pages/login_page.dart';


void main() {
  runApp(const Uygulama());
}

class Uygulama extends StatelessWidget {
  const Uygulama({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EmreGaleriApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        // İleride ekleyeceğin diğer rotalar buraya
      },
    );
  }
}
