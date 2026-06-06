import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/subject_selection_screen.dart';
import 'screens/change_password_screen.dart'; 
import 'screens/splash_screen.dart'; // INTEGRATED: Splash landing layer
import 'theme/tailwind_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://xhloiwzkoswtdmgwfoil.supabase.co',
    anonKey: 'sb_publishable_xGuRAr3G-0Z4UF4FfNHbgQ_CUIhdwTt',
  );

  runApp(const AkkaApp());
}

// Global reference for Supabase
final supabase = Supabase.instance.client;

class AkkaApp extends StatelessWidget {
  const AkkaApp({super.key});

  /// Logic: Force login if the last successful login was over 24 hours ago
  Future<bool> shouldForceLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString('last_login_date');
    if (lastLogin == null) return false; 

    final lastDate = DateTime.parse(lastLogin);
    final now = DateTime.now();
    return now.difference(lastDate).inHours >= 24; 
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akka AI Tutor',
      debugShowCheckedModeBanner: false,
      // LIGHT TAILWIND THEME
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Tailwind.slate50, 
        primaryColor: Tailwind.indigo600,
        appBarTheme: const AppBarTheme(
          backgroundColor: Tailwind.white, 
          elevation: 0,
          iconTheme: IconThemeData(color: Tailwind.slate800),
          titleTextStyle: TextStyle(
            color: Tailwind.slate800,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // STEP 1: Set default initialization view directly to the brand landing layer
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/chat': (context) => const ChatScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        
        // STEP 2: Handle routing session validation explicitly post-splash completion
        '/auth_gate': (context) => StreamBuilder<AuthState>(
          stream: supabase.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session = snapshot.data?.session;

            if (session == null) {
              return const LoginScreen();
            }

            return FutureBuilder<bool>(
              future: shouldForceLogin(),
              builder: (context, forceLoginSnapshot) {
                if (forceLoginSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: Colors.white)),
                  );
                }

                final forceLogin = forceLoginSnapshot.data ?? false;

                if (forceLogin) {
                  supabase.auth.signOut();
                  return const LoginScreen();
                }

                return const SubjectSelectionScreen();
              },
            );
          },
        ),
      },
    );
  }
}