import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/tailwind_theme.dart';
import 'reset_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String identifier;
  final bool isEmail;

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    required this.isEmail,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
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

  Future<void> _verifyOtp() async {
    final token = _otpController.text.trim();

    if (token.isEmpty || token.length < 6) {
      _showCustomSnackBar('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEmail) {
        await supabase.auth.verifyOTP(
          email: widget.identifier,
          token: token,
          type: OtpType.recovery,
        );
      } else {
        await supabase.auth.verifyOTP(
          phone: widget.identifier,
          token: token,
          type: OtpType.recovery,
        );
      }

      if (mounted) {
        _showCustomSnackBar('OTP Verified!', isError: false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showCustomSnackBar(e.message);
    } catch (e) {
      if (mounted) _showCustomSnackBar('An unexpected error occurred. Invalid OTP.');
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
                const Icon(Icons.mark_email_read, size: 80, color: Tailwind.indigo500),
                const SizedBox(height: 24),
                const Text(
                  'Verify OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Tailwind.slate800)
                ),
                const SizedBox(height: 12),
                Text(
                  'We have sent a 6-digit OTP to ${widget.identifier}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Tailwind.slate500)
                ),
                const SizedBox(height: 40),
                _buildTextField(_otpController, 'Enter 6-digit OTP', Icons.pin),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Tailwind.indigo600))
                else
                  ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Tailwind.indigo600,
                      foregroundColor: Tailwind.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl)
                    ),
                    child: const Text('Verify', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: const TextStyle(color: Tailwind.slate800, letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 18),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          counterText: "",
          labelText: label,
          labelStyle: const TextStyle(color: Tailwind.slate500, letterSpacing: 0, fontWeight: FontWeight.normal, fontSize: 14),
          prefixIcon: Icon(icon, color: Tailwind.indigo500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
