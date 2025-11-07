import 'dart:convert';
import 'package:doc/profileprofile/professional_profile_page.dart';
import 'package:doc/healthcare/hospial_profile.dart';
import 'package:doc/screens/signup_screen.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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

    /// ✅ Auto navigate if last role is saved
    Future.delayed(const Duration(seconds: 1), () {
      RoleBasedNavigationHelper.autoNavigateIfRoleSaved(context);
    });
  }

  Future<void> _prewarmServer() async {
    try {
      await http
          .get(Uri.parse('https://surgeon-search.onrender.com/api/ping'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// ✅ SIGN IN FUNCTION
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('https://surgeon-search.onrender.com/api/signin');
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userData = data['user'] ?? data['profile'] ?? {};
        final profileId = userData['_id'] ?? userData['profile_id'];
        final userType = userData['type'] ?? "Surgeon";

        await prefs.setString('login_id', const Uuid().v4());
        await saveLoginInfo(profileId ?? '', token ?? '');

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Login Successful!')));

        /// ✅ Save & Navigate by role
        await RoleBasedNavigationHelper.saveUserRole(userType);
        RoleBasedNavigationHelper.navigateBasedOnRole(context, userType);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${error['message'] ?? 'Invalid credentials'}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ LOGOUT FUNCTION — Clears saved role too
  Future<void> _logoutUser() async {
    await logout();
    await RoleBasedNavigationHelper.clearUserRole();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚪 Logged out successfully.')),
    );

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
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

                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Iconsax.sms, size: 20),
                      hintText: 'Your email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Iconsax.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText ? Iconsax.eye_slash : Iconsax.eye,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                      hintText: 'Your password',
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB3E5FC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Row(
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
                  ),
                ],
              ),
            ),

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

/// 🌐 ROLE-BASED NAVIGATION HELPER (built-in)
class RoleBasedNavigationHelper {
  static Future<void> saveUserRole(String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_role', userType);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_selected_role');
  }

  static Future<void> clearUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_selected_role');
  }

  static Future<void> navigateBasedOnRole(
    BuildContext context,
    String userType,
  ) async {
    Widget? destination;

    switch (userType) {
      case "Healthcare Organizations":
        destination = const HealthcareOrganizations();
        break;

      case "Surgeon":
        destination = const ProfessionalProfileViewPage(profileId: '');
        break;

      case "Admin":
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🧭 Admin Dashboard not yet added")),
        );
        return;

      case "Nurse":
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🧭 Nurse Dashboard not yet added")),
        );
        return;

      case "Patient":
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🧭 Patient Home not yet added")),
        );
        return;

      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("⚠️ Unknown role: $userType")));
        return;
    }

    await saveUserRole(userType);

    if (destination != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination!),
      );
    }
  }

  static Future<void> autoNavigateIfRoleSaved(BuildContext context) async {
    final savedRole = await getUserRole();
    if (savedRole != null) {
      navigateBasedOnRole(context, savedRole);
    }
  }
}
