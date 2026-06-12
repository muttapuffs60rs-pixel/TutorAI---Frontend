import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/tailwind_theme.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _showCustomSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.greenAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || password.length != 4 || !RegExp(r'^[0-9]{4}$').hasMatch(password)) {
      _showCustomSnackBar('PIN must be exactly 4 digits');
      return;
    }

    if (password != confirmPassword) {
      _showCustomSnackBar('PINs do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      if (mounted) {
        _showCustomSnackBar('PIN updated successfully! Please log in.', isError: false);
        // Ensure user is signed out so they have to log in with new PIN
        await supabase.auth.signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showCustomSnackBar(e.message);
    } catch (e) {
      if (mounted) _showCustomSnackBar('An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        backgroundColor: Tailwind.slate50,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent going back to OTP
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Tailwind.white,
              borderRadius: Tailwind.rounded2Xl,
              boxShadow: Tailwind.shadowLg,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.password, size: 80, color: Tailwind.indigo500),
                const SizedBox(height: 24),
                const Text(
                  'Set New PIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Tailwind.slate800)
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter a new 4-digit numeric PIN.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Tailwind.slate500)
                ),
                const SizedBox(height: 40),
                _buildTextField(_passwordController, 'New 4-Digit PIN', Icons.lock, isPassword: true, isPin: true),
                const SizedBox(height: 16),
                _buildTextField(_confirmPasswordController, 'Confirm New PIN', Icons.lock_outline, isPassword: true, isPin: true),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Tailwind.indigo600))
                else
                  ElevatedButton(
                    onPressed: _updatePassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Tailwind.indigo600,
                      foregroundColor: Tailwind.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl)
                    ),
                    child: const Text('Update PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isPin = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Tailwind.slate50,
        borderRadius: Tailwind.roundedXl,
        border: Border.all(color: Tailwind.slate200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isPin ? TextInputType.number : TextInputType.text,
        maxLength: isPin ? 4 : null,
        style: const TextStyle(color: Tailwind.slate800),
        decoration: InputDecoration(
          counterText: '',
          labelText: label,
          labelStyle: const TextStyle(color: Tailwind.slate500),
          prefixIcon: Icon(icon, color: Tailwind.indigo500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
