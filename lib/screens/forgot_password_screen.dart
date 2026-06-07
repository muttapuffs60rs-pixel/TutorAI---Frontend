import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/tailwind_theme.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
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

  Future<void> _sendOtp() async {
    String identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      _showCustomSnackBar('Please enter your email or phone number');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      bool isEmail = identifier.contains('@');
      
      if (isEmail) {
        // Send email reset OTP
        await supabase.auth.resetPasswordForEmail(identifier);
      } else {
        // Send phone reset OTP
        // Ensure +91 if length is 10
        if (identifier.length == 10 && !identifier.startsWith('+')) {
          identifier = '+91$identifier';
        }
        await supabase.auth.signInWithOtp(phone: identifier);
      }

      if (mounted) {
        _showCustomSnackBar('OTP sent successfully to $identifier!', isError: false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              identifier: identifier,
              isEmail: isEmail,
            ),
          ),
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
        iconTheme: const IconThemeData(color: Tailwind.slate800),
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
                const Icon(Icons.lock_reset, size: 80, color: Tailwind.indigo500),
                const SizedBox(height: 24),
                const Text(
                  'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Tailwind.slate800)
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter your registered email or phone number and we will send you an OTP to reset your password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Tailwind.slate500)
                ),
                const SizedBox(height: 40),
                _buildTextField(_identifierController, 'Email or Phone Number', Icons.person_outline),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Tailwind.indigo600))
                else
                  ElevatedButton(
                    onPressed: _sendOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Tailwind.indigo600,
                      foregroundColor: Tailwind.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl)
                    ),
                    child: const Text('Send OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Tailwind.slate50,
        borderRadius: Tailwind.roundedXl,
        border: Border.all(color: Tailwind.slate200),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Tailwind.slate800),
        decoration: InputDecoration(
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
