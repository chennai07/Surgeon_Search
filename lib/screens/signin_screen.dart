import 'dart:convert';
import 'package:doc/healthcare/hospial_profile.dart';
import 'package:doc/profileprofile/profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/screens/signup_screen.dart';
import 'package:doc/profileprofile/professional_profile_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prewarmServer();
  }

  /// 🌐 Wake up backend (Render) to prevent cold start delay
  Future<void> _prewarmServer() async {
    try {
      await http
          .get(Uri.parse('https://surgeon-search.onrender.com/api/ping'))
          .timeout(const Duration(seconds: 5));
      debugPrint('✅ Server is awake');
    } catch (_) {
      debugPrint('⚠️ Could not prewarm server.');
    }
  }

  /// ✅ LOGIN FUNCTION
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    final url = Uri.parse('https://surgeon-search.onrender.com/api/signin');
    const uuid = Uuid();

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Login successful: $data');

        final token = data['token'];
        final userData = data['user'] ?? data['profile'] ?? data;

        // 🧠 Extract or create profile ID
        String profileId =
            (userData['_id']?.toString() ??
                    userData['profile_id']?.toString() ??
                    uuid.v4())
                .trim();

        // ✅ Save session
        await SessionManager.saveUserId(profileId);
        await SessionManager.saveToken(token ?? '');

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Login Successful!')));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfessionalProfileViewPage(profileId: profileId),
          ),
        );
      } else {
        String message = 'Invalid credentials';
        try {
          final error = jsonDecode(response.body);
          if (error is Map && error['message'] != null) {
            message = error['message'];
          }
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ $message')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ✅ ROLE-BASED REDIRECT FUNCTION (added safely)
  Future<void> handleLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString('user_role');

    if (role == 'health_organization') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HealthcareOrganizations()),
      );
    } else if (role == 'sajan') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const EditProfessionalProfilePage(
            profileId: '',
            existingData: {},
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown role, please sign up again.')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text.rich(
                    TextSpan(
                      text: "Let’s ",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  Center(child: Image.asset('assets/logo2.png', height: 150)),
                  const SizedBox(height: 60),

                  // 📨 Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Iconsax.sms, size: 20),
                      hintText: 'Your email',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔒 Password Field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Iconsax.lock, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Iconsax.eye_slash : Iconsax.eye,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                      hintText: 'Your password',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 🔘 Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔗 Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don’t have an account?",
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF003366),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ⏳ Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
