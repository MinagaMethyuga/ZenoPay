import 'package:flutter/material.dart';
import 'package:zenopay/Pages/BudgetingPage.dart';
import 'package:zenopay/Pages/ChallengesPage.dart';
import 'package:zenopay/Pages/Leaderboards.dart';
import 'package:zenopay/Pages/ProfilePage.dart';
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
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/home':
            page = const Home();
            break;
          case '/login':
            page = const Login();
            break;
          case '/register':
            page = const Register();
            break;
          case '/onboarding':
            page = const OnboardingJourney();
            break;
          case '/ZenoChallenge':
            page = const ChallengesPage();
            break;
          case '/Budgeting':
            page = const BudgetingPage();
            break;
          case '/Leaderboards':
            page = const Leaderboards();
            break;
          case '/profile':
            page = const ProfilePage();
            break;
          default:
            page = const Login();
        }

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.05, 0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            var offsetAnimation = animation.drive(tween);
            var fadeAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 280),
        );
      },
    );
  }
}