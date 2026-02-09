import 'package:flutter/material.dart';
import 'package:zenopay/Pages/ChallengesPage.dart';
import 'package:zenopay/Pages/Leaderboards.dart';
import 'package:zenopay/services/auth_api.dart';

import 'Pages/Login.dart';
import 'Pages/Home.dart';
import 'Pages/register.dart';
import 'Pages/OnboardingJourney.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthApi api = AuthApi();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ Logout when app goes background / closed from recents
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      await api.logout();
      navKey.currentState?.pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      title: 'ZenoPay',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/home': (context) => const Home(),
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
        '/onboarding': (context) => const OnboardingJourney(),
        '/ZenoChallenge': (context) => const ChallengesPage(),
        '/Leaderboards': (context) => const Leaderboards(),
      },
    );
  }
}