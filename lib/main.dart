

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_management_todo/ProfileView/Profile_Screen.dart';
import 'package:task_management_todo/Settings/Setting_provider.dart';
import 'Screens/forgot_password.dart';
import 'Screens/home_screen.dart';
import 'Screens/login_screen.dart';
import 'Screens/signup_screen.dart';
import 'Views/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Task Management App',
          theme: ThemeData(
            brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
            primarySwatch: Colors.teal,
            scaffoldBackgroundColor:
                settings.isDarkMode ? Colors.black : Colors.white,
            appBarTheme: AppBarTheme(
              backgroundColor: settings.isDarkMode ? Colors.black : Colors.teal,
              iconTheme: IconThemeData(
                  color: settings.isDarkMode ? Colors.white : Colors.white),
            ),
          ),
          routes: {
            '/onboarding': (_) => const OnBoardingPage(),
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignUpScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/home': (_) => const HomeScreen(),
            '/profile': (_) => const Profile(),

          },
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const OnBoardingPage();
      },
    );
  }
}
