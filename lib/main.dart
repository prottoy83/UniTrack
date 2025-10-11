import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitrack/pages/setupProfile.dart';
import 'theme/LightTheme.dart';
import 'theme/DarkTheme.dart';
import 'services/database_service.dart';
import 'pages/dashboard.dart';
import 'providers/theme_provider.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'UniTrack',
          debugShowCheckedModeBanner: false,
          theme: LightTheme.theme,
          darkTheme: DarkTheme.theme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkProfileAndNavigate();
  }

  Future<void> _checkProfileAndNavigate() async {
    // Add a small delay for splash effect
    await Future.delayed(const Duration(seconds: 1));
    
    // Initialize database to ensure all tables exist
    await DatabaseService.instance.initializeDatabase();
    
    final profileData = await DatabaseService.instance.getProfileData();
    
    if (!mounted) return;
    
    if (profileData != null) {
      // Profile exists, navigate to dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else {
      // No profile, navigate to setup semester
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SetupProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'UniTrack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
