import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/screens/reset_password_screen.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordOtpScreen({super.key, required this.email});

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  List<TextEditingController> controllers =
      List.generate(4, (_) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());

  int counter = 30;
  bool canResend = false;
  bool isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void startTimer() {
    _timer?.cancel();
    counter = 30;
    canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (counter == 0) {
        setState(() => canResend = true);
        timer.cancel();
      } else {
        setState(() => counter--);
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!canResend) return;

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://13.203.67.154:3000/api/password/forgot');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear OTP fields
        for (var controller in controllers) {
          controller.clear();
        }
        // Restart timer
        startTimer();
      } else {
        String message = 'Failed to resend OTP';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            message = body['message'];
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    String otp = controllers.map((c) => c.text).join();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid 4-digit OTP")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://13.203.67.154:3000/api/password/otp-verify');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": widget.email,
          "otp": otp,
        }),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP Verified Successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Reset Password Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: widget.email),
          ),
        );
      } else {
        String message = "Invalid OTP";
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            message = body['message'];
          }
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 28),
                  ),

                  const SizedBox(height: 15),

                  // Title
                  RichText(
                    text: const TextSpan(
                      text: "Verify ",
                      style: TextStyle(fontSize: 28, color: Colors.black),
                      children: [
                        TextSpan(
                          text: "OTP",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "We sent an OTP code to your email,",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                  const SizedBox(height: 5),

                  Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // OTP Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return SizedBox(
                        height: 65,
                        width: 65,
                        child: TextField(
                          controller: controllers[index],
                          focusNode: focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 3) {
                              focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 25),

                  // Resend Timer
                  Center(
                    child: GestureDetector(
                      onTap: canResend ? _resendOtp : null,
                      child: Text.rich(
                        TextSpan(
                          text: "Didn't receive the OTP? ",
                          style: TextStyle(color: Colors.grey.shade600),
                          children: [
                            TextSpan(
                              text: canResend
                                  ? "Resend OTP"
                                  : "Resend in 00:${counter.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                color: canResend ? Colors.blueAccent : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Verify OTP",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Info Text
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Please check your spam folder if you",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "don't see the email in your inbox",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Loading Overlay
            if (isLoading)
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
