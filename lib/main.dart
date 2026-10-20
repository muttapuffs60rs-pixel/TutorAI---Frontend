import 'services/referral_invite.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/legal_policy_screen.dart';
import 'screens/policy_acceptance_gate.dart';
import 'screens/change_password_screen.dart';
import 'screens/live_quiz/live_quiz_entry_screen.dart';
import 'screens/home_selection_screen.dart';
import 'theme/tailwind_theme.dart';

// ============================================================
// CREDENTIALS — for local dev, values are hardcoded below.
// For production builds, use --dart-define instead:
//   flutter run \
//     --dart-define=SUPABASE_URL=https://xhloiwzkoswtdmgwfoil.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=sb_publishable_xGuRAr3G-0Z4UF4FfNHbgQ_CUIhdwTt
// ============================================================
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://xhloiwzkoswtdmgwfoil.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_xGuRAr3G-0Z4UF4FfNHbgQ_CUIhdwTt',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await rememberReferral(Uri.base);

  // Initialize Supabase
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

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

  Widget _buildAuthGate(BuildContext context) => StreamBuilder<AuthState>(
    stream: supabase.auth.onAuthStateChange,
    builder: (context, snapshot) {
      final session = snapshot.data?.session ?? supabase.auth.currentSession;

      if (session == null) {
        return const LoginScreen();
      }

      return FutureBuilder<bool>(
        future: shouldForceLogin(),
        builder: (context, forceLoginSnapshot) {
          if (forceLoginSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          final forceLogin = forceLoginSnapshot.data ?? false;

          if (forceLogin) {
            supabase.auth.signOut();
            return const LoginScreen();
          }

          return const HomeSelectionScreen();
        },
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arivora',
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          PolicyAcceptanceGate(child: child ?? const SizedBox.shrink()),
      // PASTEL LEARNING THEME
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Tailwind.slate50,
        primaryColor: Tailwind.indigo600,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: Tailwind.indigo600,
              brightness: Brightness.light,
            ).copyWith(
              primary: Tailwind.indigo600,
              onPrimary: Tailwind.white,
              secondary: Tailwind.blue500,
              surface: Tailwind.white,
              onSurface: Tailwind.slate800,
            ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Tailwind.indigo600,
            foregroundColor: Tailwind.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedLg),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Tailwind.white,
          border: OutlineInputBorder(borderRadius: Tailwind.roundedLg),
          enabledBorder: OutlineInputBorder(
            borderRadius: Tailwind.roundedLg,
            borderSide: const BorderSide(color: Tailwind.slate200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: Tailwind.roundedLg,
            borderSide: const BorderSide(color: Tailwind.indigo600, width: 2),
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Tailwind.indigo600,
        ),
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
      // Open the authentication flow immediately, without a launch splash.
      home: _buildAuthGate(context),
      routes: {
        '/terms': (_) => const LegalPolicyScreen(policy: LegalPolicy.terms),
        '/refund-policy': (_) =>
            const LegalPolicyScreen(policy: LegalPolicy.refunds),
        '/login': (context) => const LoginScreen(),
        '/chat': (context) => const HomeSelectionScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        '/live-quiz': (context) => StreamBuilder<AuthState>(
          stream: supabase.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session =
                snapshot.data?.session ?? supabase.auth.currentSession;
            if (session != null) {
              return const LiveQuizEntryScreen();
            }
            // Not logged in — redirect to login, then come back
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/login');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),

        // Validate restored sessions and direct authentication links.
        '/auth_gate': _buildAuthGate,
      },
    );
  }
}
