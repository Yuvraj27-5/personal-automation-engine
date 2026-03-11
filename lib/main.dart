import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'data/local/database_helper.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await DatabaseHelper.initialize();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: AutomationEngineApp()));
}

class AutomationEngineApp extends StatelessWidget {
  const AutomationEngineApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoEngine',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      // Skip splash on refresh if already logged in
      home: FirebaseAuth.instance.currentUser != null
          ? const HomeScreen()
          : const SplashScreen(),
    );
  }
}

// Auth gate — shows home if logged in, login if not
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading only briefly
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0E1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
          );
        }
        // Already logged in → go straight to home
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        // Not logged in → show login
        return const LoginScreen();
      },
    );
  }
}