import 'package:flutter/material.dart';
import 'package:zenopay/core/app_nav_key.dart';
import 'package:zenopay/Pages/BudgetingPage.dart';
import 'package:zenopay/Pages/ChallengesPage.dart';
import 'package:zenopay/Pages/Leaderboards.dart';
import 'package:zenopay/Pages/ProfilePage.dart';
import 'package:zenopay/services/auth_api.dart';
import 'package:zenopay/services/budget_notification_service.dart';
import 'package:zenopay/state/app_theme.dart';
import 'package:zenopay/theme/zenopay_colors.dart';

import 'Pages/Login.dart';
import 'Pages/Home.dart';
import 'Pages/register.dart';
import 'Pages/OnboardingJourney.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BudgetNotificationService.initialize();
  await AppTheme.init();
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

  static const Color _accent = Color(0xFF4F6DFF);
  static const Color _surfaceLight = Color(0xFFF8FAFC);
  static const Color _surfaceDark = Color(0xFF0F172A);
  static const Color _cardLight = Colors.white;
  static const Color _cardDark = Color(0xFF1E293B);
  static const Color _textPrimaryLight = Color(0xFF1E2A3B);
  static const Color _textPrimaryDark = Color(0xFFF8FAFC);
  static const Color _textSecondaryLight = Color(0xFF64748B);
  static const Color _textSecondaryDark = Color(0xFF94A3B8);

  ThemeData _lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _accent,
        surface: _surfaceLight,
        onSurface: _textPrimaryLight,
        onSurfaceVariant: _textSecondaryLight,
      ),
      scaffoldBackgroundColor: _surfaceLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceLight,
        foregroundColor: _textPrimaryLight,
        elevation: 0,
      ),
      cardColor: _cardLight,
      extensions: const [ZenoPayColors.light],
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _accent,
        surface: _surfaceDark,
        onSurface: _textPrimaryDark,
        onSurfaceVariant: _textSecondaryDark,
      ),
      scaffoldBackgroundColor: _surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: _surfaceDark,
        foregroundColor: _textPrimaryDark,
        elevation: 0,
      ),
      cardColor: _cardDark,
      extensions: const [ZenoPayColors.dark],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.notifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          navigatorKey: navKey,
          title: 'ZenoPay',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: themeMode,
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
      },
    );
  }
}