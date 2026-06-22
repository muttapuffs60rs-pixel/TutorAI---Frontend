import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; 
import '../theme/tailwind_theme.dart';
import 'home_selection_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Updated to reflect that this field can be Email OR Phone
  final _identifierController = TextEditingController(); 
  final _passwordController = TextEditingController();
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

  // Dual Login Logic: Detects if input is an email or a phone number
  Future<void> _signIn() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showCustomSnackBar('Please enter your email/phone and password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (identifier.contains('@')) {
        // Log in via Email
        await supabase.auth.signInWithPassword(email: identifier, password: password);
      } else {
        // Log in via Phone[cite: 3]
        // Note: Ensure '+91' or your country code logic is handled
        await supabase.auth.signInWithPassword(phone: identifier, password: password);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeSelectionScreen()));
      }
    } on AuthException catch (e) {
      if (mounted) _showCustomSnackBar(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tailwind.slate50, 
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
                Image.asset(
                  'assets/images/app_icon.png',
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 80, color: Tailwind.indigo500),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Tutor Preethi', 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Tailwind.slate800)
                ),
                const SizedBox(height: 40),
                _buildTextField(_identifierController, 'Email or Mobile Number', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Tailwind.indigo600))
                else ...[
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      backgroundColor: Tailwind.indigo600, 
                      foregroundColor: Tailwind.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl)
                    ),
                    child: const Text('Log In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Forgot Password?', style: TextStyle(color: Tailwind.indigo600, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
                    child: const Text('New user? Create an account here', style: TextStyle(color: Tailwind.slate600, fontWeight: FontWeight.w500)),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // NEW: Phone Controller[cite: 3]
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _showWelcomeCarousel(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        PageController _pageController = PageController();
        
        return StatefulBuilder(
          builder: (context, setState) {
            int _currentPage = _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0;

            List<Widget> _slides = [
              _buildSlide(
                "Hello $name!",
                "Welcome to Tutor Preethi! Idhu unnoda mobile tuition. Entha nerathulayum, enga irunthum nee doubts ketkalaam. Help panna ready!",
                Icons.sentiment_very_satisfied,
              ),
              _buildSlide(
                "Check your knowledge!",
                "Nee padicha specific subject and unit-la Quiz generate panni un knowledge-ah check pannalaam.",
                Icons.quiz_outlined,
              ),
              _buildSlide(
                "Start Learning!",
                "Enjoy learning and score more marks. All the best for your exams!",
                Icons.auto_awesome,
              ),
            ];

            return AlertDialog(
              backgroundColor: Tailwind.white, 
              shape: RoundedRectangleBorder(borderRadius: Tailwind.rounded2Xl),
              content: SizedBox(
                height: 320,
                width: double.maxFinite,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) => setState(() {}),
                        children: _slides,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${_currentPage + 1} / 3", style: const TextStyle(color: Tailwind.slate500)),
                        TextButton(
                          onPressed: () {
                            if (_currentPage < 2) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300), 
                                curve: Curves.easeIn
                              );
                            } else {
                              Navigator.of(context, rootNavigator: true).pop();
                              Future.delayed(Duration.zero, () {
                                if (mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const HomeSelectionScreen()), 
                                    (route) => false
                                  );
                                }
                              });
                            }
                          },
                          child: Text(
                            _currentPage == 2 ? "START" : "NEXT",
                            style: const TextStyle(color: Tailwind.indigo600, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSlide(String title, String desc, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 60, color: Tailwind.indigo500),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Tailwind.slate800)),
        const SizedBox(height: 12),
        Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Tailwind.slate600)),
      ],
    );
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim(); // Capture Phone[cite: 3]
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    // Updated validation to include phone
    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showCustomSnackBar('Please fill out all fields!');
      return;
    }
    if (password != confirm) {
      _showCustomSnackBar('Passwords do not match!');
      return;
    }
    // Simple 10-digit validation for mobile
    if (phone.length < 10) {
      _showCustomSnackBar('Please enter a valid mobile number');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Updated to send both 'username' and 'phone_number' to metadata
      await supabase.auth.signUp(
        email: email, 
        password: password, 
        data: {
          'username': name,
          'phone_number': phone, 
        }
      );
      if (mounted) _showWelcomeCarousel(name);
    } on AuthException catch (e) {
      if (mounted) _showCustomSnackBar(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tailwind.slate50,
      appBar: AppBar(
        title: const Text('Create Account'), 
        backgroundColor: Colors.transparent, 
        elevation: 0,
        iconTheme: const IconThemeData(color: Tailwind.slate800),
        titleTextStyle: const TextStyle(color: Tailwind.slate800, fontSize: 20, fontWeight: FontWeight.bold),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildField(_nameController, 'Full Name', Icons.person),
                const SizedBox(height: 16),
                _buildField(_phoneController, 'Mobile Number', Icons.phone, isPhone: true),
                const SizedBox(height: 16),
                _buildField(_emailController, 'Email', Icons.email),
                const SizedBox(height: 16),
                _buildField(_passwordController, 'Password', Icons.lock, isPass: true),
                const SizedBox(height: 16),
                _buildField(_confirmPasswordController, 'Confirm Password', Icons.lock_clock, isPass: true),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Tailwind.indigo600))
                else
                  ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      backgroundColor: Tailwind.indigo600, 
                      foregroundColor: Tailwind.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: Tailwind.roundedXl)
                    ),
                    child: const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Updated helper to handle phone keyboard type[cite: 3]
  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPass = false, bool isPhone = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Tailwind.slate50,
        borderRadius: Tailwind.roundedXl,
        border: Border.all(color: Tailwind.slate200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
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