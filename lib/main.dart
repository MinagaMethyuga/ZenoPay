import 'package:flutter/material.dart';
import 'package:zenopay/Pages/ChallengesPage.dart';
import 'package:zenopay/Pages/Leaderboards.dart';

import 'Pages/Login.dart';
import 'Pages/Home.dart';
import 'Pages/register.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZenoPay',
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const Home(),
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
        '/ZenoChallenge': (context) => const ChallengesPage(),
        '/Leaderboards': (context) => const Leaderboards(),
      },
    );
  }
}
