import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:doc/healthcare/hospial_form.dart';
import 'package:doc/healthcare/hospital_profile.dart';
import 'package:doc/Navbar.dart';
import 'package:doc/profileprofile/surgeon_form.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';
import 'package:doc/model/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/screens/signup_screen.dart';

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

  String? _extractProfileId(dynamic source) {
    if (source == null) return null;

    String? normalize(dynamic value) {
      if (value == null) return null;
      if (value is Map && value.containsKey(r'$oid')) {
        final oidValue = value[r'$oid'];
        final oidString = oidValue?.toString().trim();
        if (oidString != null && oidString.isNotEmpty) return oidString;
      }
      final stringValue = value.toString().trim();
      return stringValue.isEmpty ? null : stringValue;
    }

    final keysToCheck = const {
      'profile_id',
      'profileId',
      'profileID',
      '_id',
      'id',
      'user_id',
      'userId',
      'doctor_id',
      'doctorId',
    };

    if (source is Map) {
      for (final entry in source.entries) {
        if (keysToCheck.contains(entry.key)) {
          final normalized = normalize(entry.value);
          if (normalized != null) return normalized;
        }

        if (entry.value is Map || entry.value is Iterable) {
          final nested = _extractProfileId(entry.value);
          if (nested != null) return nested;
        } else {
          final normalized = normalize(entry.value);
          if (normalized != null && keysToCheck.any(entry.key.toLowerCase().contains)) {
            return normalized;
          }
        }
      }
    } else if (source is Iterable) {
      for (final item in source) {
        final nested = _extractProfileId(item);
        if (nested != null) return nested;
      }
    } else {
      final normalized = normalize(source);
      if (normalized != null) return normalized;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _prewarmServer();
  }

  /// Wake up backend (Render) to prevent cold start delay
  Future<void> _prewarmServer() async {
    try {
      // Use root path which always exists and still wakes the instance
      await http
          .get(Uri.parse('http://13.203.67.154:3000/'))
          .timeout(const Duration(seconds: 8));
      debugPrint(' Server is awake');
    } catch (_) {
      debugPrint(' Could not prewarm server.');
    }
  }

  /// Helper: POST with retries/backoff to tolerate cold starts or transient TLS drops
  Future<http.Response> _postWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    int attempts = 3,
  }) async {
    final delays = <Duration>[
      Duration.zero,
      const Duration(seconds: 2),
      const Duration(seconds: 5),
    ];

    for (var i = 0; i < attempts; i++) {
      try {
        return await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 30));
      } on TimeoutException catch (_) {
        if (i == attempts - 1) rethrow;
      } on SocketException catch (_) {
        if (i == attempts - 1) rethrow;
      } on HandshakeException catch (_) {
        if (i == attempts - 1) rethrow;
      }
      // Backoff before next try
      await Future.delayed(delays[i]);
    }
    // Should never reach here
    throw Exception('Request failed after retries');
  }

  /// LOGIN FUNCTION
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

    final url = Uri.parse('http://13.203.67.154:3000/api/signin');
    const uuid = Uuid();

    try {
      final response = await _postWithRetry(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final root = jsonDecode(response.body);
        final data = root is Map && root['data'] != null ? root['data'] : root;
        debugPrint(' Login successful: $data');

        final token = (data is Map) ? data['token'] : null;
        final userData = (data is Map)
            ? (data['user'] ?? data['profile'] ?? data)
            : data;

        String? role = (userData is Map)
            ? (userData['type'] ?? userData['role'] ?? (data is Map ? (data['type'] ?? data['role']) : null))?.toString()
            : null;

        bool healthProfile = false;
        if (userData is Map) {
          final rawHp = userData['healthprofile'] ?? userData['healthProfile'];
          if (rawHp is bool) {
            healthProfile = rawHp;
          } else if (rawHp is String) {
            healthProfile = rawHp.toLowerCase() == 'true';
          }
        } else if (data is Map) {
          final rawHp = data['healthprofile'] ?? data['healthProfile'];
          if (rawHp is bool) {
            healthProfile = rawHp;
          } else if (rawHp is String) {
            healthProfile = rawHp.toLowerCase() == 'true';
          }
        }

        // Extract or create profile ID (prefer deep extraction, fallback to fields/uuid)
        final extractedProfileId = _extractProfileId(userData) ??
            (data is Map ? _extractProfileId(data['profile']) : null) ??
            _extractProfileId(data);
        String profileId =
            ((extractedProfileId ??
                        (userData is Map ? userData['_id']?.toString() : null) ??
                        (userData is Map ? userData['profile_id']?.toString() : null) ??
                        (userData is Map ? userData['id']?.toString() : null) ??
                        '') as String)
                    .trim();
        if (profileId.isEmpty) profileId = uuid.v4();

        // Save session
        await SessionManager.saveUserId(profileId);
        await SessionManager.saveProfileId(profileId);
        await SessionManager.saveToken(token ?? '');
        if (role != null && role.isNotEmpty) {
          await SessionManager.saveRole(role);
        }
        await SessionManager.saveHealthProfileFlag(healthProfile);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(' Login Successful!')));

        final rl = (role ?? '').toLowerCase().trim();
        if (rl.contains('hospital') || rl.contains('health') || rl.contains('org')) {
          // CRITICAL: Extract the user's _id from signin response
          // The backend uses this _id as the primary identifier for healthcare profiles
          String? healthcareIdFromResponse;
          
          // First, try to get _id (MongoDB primary key) - this is what the backend uses!
          if (userData is Map) {
            final raw = (userData['_id'] ??
                    userData['id'] ??
                    userData['healthcare_id'] ??
                    userData['healthcareId'] ??
                    userData['healthcareID'])
                ?.toString()
                .trim();
            if (raw != null && raw.isNotEmpty) {
              healthcareIdFromResponse = raw;
              print('🔑 Found ID in userData: $raw');
            }
          }
          
          // If not found in userData, try data level
          if (healthcareIdFromResponse == null || healthcareIdFromResponse.isEmpty) {
            if (data is Map) {
              final raw = (data['_id'] ??
                      data['id'] ??
                      data['healthcare_id'] ??
                      data['healthcareId'] ??
                      data['healthcareID'])
                  ?.toString()
                  .trim();
              if (raw != null && raw.isNotEmpty) {
                healthcareIdFromResponse = raw;
                print('🔑 Found ID in data: $raw');
              }
            }
          }

          print('🔑 Healthcare ID from login response: $healthcareIdFromResponse');

          final existingHid = await SessionManager.getHealthcareId();
          print('🔑 Existing stored healthcare ID: $existingHid');
          
          // Priority: response _id > existing stored > profileId
          final baseHid = (healthcareIdFromResponse != null &&
                  healthcareIdFromResponse.isNotEmpty)
              ? healthcareIdFromResponse
              : ((existingHid != null && existingHid.isNotEmpty)
                  ? existingHid
                  : profileId);

          print('🔑 ✅ Using healthcare ID: $baseHid (source: ${healthcareIdFromResponse != null ? "response._id" : existingHid != null ? "stored" : "profileId"})');

          await SessionManager.saveHealthcareId(baseHid);
          
          print('🔑 📋 Starting profile fetch process...');
          print('🔑 📋 healthProfile flag: $healthProfile');
          
          // Try to fetch profile - try multiple IDs for backward compatibility
          Map<String, dynamic>? navHospitalData;
          String? workingHealthcareId;
          
          // List of IDs to try (for backward compatibility with old profiles)
          final idsToTry = <String>[
            baseHid,
            if (existingHid != null && existingHid != baseHid) existingHid,
            if (profileId != baseHid && profileId != existingHid) profileId,
          ];
          
          print('🔑 Trying to fetch profile with IDs: $idsToTry');
          
          for (final tryId in idsToTry) {
            try {
              final url = Uri.parse('http://13.203.67.154:3000/api/healthcare/healthcare-profile/$tryId');
              final resp = await http.get(url).timeout(const Duration(seconds: 10));
              
              print('🔑 Tried ID $tryId: status ${resp.statusCode}');
              
              if (resp.statusCode == 200) {
                final body = resp.body.trimLeft();
                dynamic parsed;
                try { parsed = jsonDecode(body); } catch (_) { parsed = {}; }
                final payload = (parsed is Map && parsed['data'] != null) ? parsed['data'] : parsed;
                final mapPayload = (payload is Map<String, dynamic>) ? payload : <String, dynamic>{};

                // Check if the profile has meaningful data
                final hasValidProfile = mapPayload.isNotEmpty && 
                    (mapPayload['hospitalName']?.toString().trim().isNotEmpty == true ||
                     mapPayload['email']?.toString().trim().isNotEmpty == true ||
                     mapPayload['phoneNumber']?.toString().trim().isNotEmpty == true);
                
                if (hasValidProfile) {
                  print('🔑 ✅ Found valid profile with ID: $tryId');
                  
                  // Extract the canonical healthcare_id from the profile
                  final canonicalHid = (mapPayload['_id'] ??
                          mapPayload['healthcare_id'] ??
                          mapPayload['healthcareId'] ??
                          mapPayload['healthcareProfileId'] ??
                          tryId)
                      .toString()
                      .trim();
                  
                  // Save the working ID
                  await SessionManager.saveHealthcareId(canonicalHid);
                  workingHealthcareId = canonicalHid;
                  
                  navHospitalData = Map<String, dynamic>.from(mapPayload);
                  navHospitalData['healthcare_id'] = canonicalHid;
                  
                  print('🔑 💾 Saved canonical healthcare_id: $canonicalHid');
                  break; // Found profile, stop trying
                }
              }
            } catch (e) {
              print('🔑 Error fetching with ID $tryId: $e');
              continue; // Try next ID
            }
          }
          
          if (!mounted) return;
          
          // Navigate based on whether we found a profile
          if (navHospitalData != null && workingHealthcareId != null) {
            // Profile found! Navigate to dashboard
            print('🔑 ✅ Navigating to Navbar with profile data');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Navbar(hospitalData: navHospitalData!)),
            );
          } else {
            // No profile found - show form to create one
            print('🔑 ⚠️ No profile found with any ID, navigating to HospitalForm');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HospitalForm(healthcareId: baseHid)),
            );
          }
        } else if (rl.contains('surgeon') || rl.contains('doctor')) {
          try {
            final res = await ApiService.fetchProfileInfo(profileId);
            if (res['success'] == true) {
              final body = res['data'];
              final data = body is Map && body['data'] != null ? body['data'] : body;
              final p = data is Map && data['profile'] != null ? data['profile'] : data;

              final hasValidProfile = p is Map &&
                  (((p['fullName'] ?? p['fullname'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty ==
                          true) ||
                      (p['email']?.toString().trim().isNotEmpty == true) ||
                      (p['phoneNumber']?.toString().trim().isNotEmpty == true));

              if (hasValidProfile) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfessionalProfileViewPage(
                      profileId: profileId,
                    ),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurgeonForm(
                      profileId: profileId,
                      existingData: const {},
                    ),
                  ),
                );
              }
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SurgeonForm(
                    profileId: profileId,
                    existingData: const {},
                  ),
                ),
              );
            }
          } catch (_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SurgeonForm(
                  profileId: profileId,
                  existingData: const {},
                ),
              ),
            );
          }
        } else {
          // Default to Surgeon profile flow if role is unknown
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SurgeonForm(
                profileId: profileId,
                existingData: const {},
              ),
            ),
          );
        }
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
    } on TimeoutException catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⏳ Server is taking too long to respond. Please try again.')));
    } on HandshakeException catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('🔒 Secure connection failed. Check date/time, VPN/proxy, or try a different network.')));
    } on SocketException catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('📡 Network error. Check your internet connection and try again.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('⚠️ Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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