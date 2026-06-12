import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; 

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Track password field visibility independently
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showCustomSnackBar({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6.0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFD00000) : const Color(0xFF38B000),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null || user.email == null) throw Exception("No authenticated user found");

      // 1. Verify current password by re-authenticating
      await supabase.auth.signInWithPassword(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      // 2. Update to the new password
      await supabase.auth.updateUser(
        UserAttributes(
          password: _newPasswordController.text.trim(),
        ),
      );

      if (!mounted) return;
      _showCustomSnackBar(message: "Password updated successfully!", isError: false);
      
      Navigator.pop(context); 
    } catch (e) {
      if (!mounted) return;
      
      String clearErrorMessage = e.toString().contains("Invalid login credentials")
          ? "The current password you entered is incorrect."
          : "Could not update password. Please check your network connection.";
          
      _showCustomSnackBar(message: clearErrorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themePurple = Color(0xFF7B2CBF);
    const Color darkPurple = Color(0xFF5A189A);

    return Scaffold(
      backgroundColor: themePurple,
      appBar: AppBar(
        backgroundColor: darkPurple,
        title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Update your credentials securely.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Current Password Field with visibility switch
                _buildPasswordField(
                  controller: _currentPasswordController,
                  label: 'Current Password',
                  isObscured: _obscureCurrent,
                  onToggleVisibility: () {
                    setState(() => _obscureCurrent = !_obscureCurrent);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your current password';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // New PIN Field
                _buildPasswordField(
                  controller: _newPasswordController,
                  label: 'New 4-Digit PIN',
                  isObscured: _obscureNew,
                  isPin: true,
                  onToggleVisibility: () {
                    setState(() => _obscureNew = !_obscureNew);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a new PIN';
                    if (value.length != 4) return 'PIN must be exactly 4 digits';
                    if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) return 'PIN must contain only numbers';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm PIN Field
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm New PIN',
                  isObscured: _obscureConfirm,
                  isPin: true,
                  onToggleVisibility: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                  validator: (value) {
                    if (value != _newPasswordController.text) return 'PINs do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: darkPurple, strokeWidth: 2),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(color: darkPurple, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UPDATED WORKFLOW: Standardized to accept visibility state variables and explicit toggle callbacks
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    bool isPin = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      keyboardType: isPin ? TextInputType.number : TextInputType.text,
      maxLength: isPin ? 4 : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        counterText: '',  // hide the "0/4" counter on PIN fields
        suffixIcon: IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white70,
          ),
          onPressed: onToggleVisibility,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.amber),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: const Color(0xFF5A189A).withValues(alpha: 0.3),
      ),
    );
  }
}