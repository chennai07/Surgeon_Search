import 'package:flutter/material.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Diagnostic tool to check healthcare_id and profile status
/// Add this as a temporary button in your app to debug the issue
class HealthcareDiagnostic extends StatefulWidget {
  const HealthcareDiagnostic({super.key});

  @override
  State<HealthcareDiagnostic> createState() => _HealthcareDiagnosticState();
}

class _HealthcareDiagnosticState extends State<HealthcareDiagnostic> {
  String diagnosticResult = 'Tap "Run Diagnostic" to check your healthcare profile status';
  bool isRunning = false;

  Future<void> runDiagnostic() async {
    setState(() {
      isRunning = true;
      diagnosticResult = 'Running diagnostic...\n\n';
    });

    final buffer = StringBuffer();
    
    try {
      // Check session storage
      buffer.writeln('=== SESSION STORAGE ===');
      final healthcareId = await SessionManager.getHealthcareId();
      final profileId = await SessionManager.getProfileId();
      final userId = await SessionManager.getUserId();
      final role = await SessionManager.getRole();
      final token = await SessionManager.getToken();
      
      buffer.writeln('Healthcare ID: ${healthcareId ?? "NOT SET"}');
      buffer.writeln('Profile ID: ${profileId ?? "NOT SET"}');
      buffer.writeln('User ID: ${userId ?? "NOT SET"}');
      buffer.writeln('Role: ${role ?? "NOT SET"}');
      buffer.writeln('Token: ${token != null && token.isNotEmpty ? "SET (${token.length} chars)" : "NOT SET"}');
      buffer.writeln('');

      // Check if healthcare profile exists
      if (healthcareId != null && healthcareId.isNotEmpty) {
        buffer.writeln('=== HEALTHCARE PROFILE CHECK ===');
        buffer.writeln('Checking profile for ID: $healthcareId');
        
        try {
          final url = Uri.parse('http://13.203.67.154:3000/api/healthcare/healthcare-profile/$healthcareId');
          final response = await http.get(url).timeout(const Duration(seconds: 10));
          
          buffer.writeln('Status Code: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            buffer.writeln('✅ Profile EXISTS');
            
            try {
              final data = jsonDecode(response.body);
              final profile = (data is Map && data['data'] != null) ? data['data'] : data;
              
              if (profile is Map) {
                buffer.writeln('');
                buffer.writeln('Profile Details:');
                buffer.writeln('- Hospital Name: ${profile['hospitalName'] ?? "NOT SET"}');
                buffer.writeln('- Email: ${profile['email'] ?? "NOT SET"}');
                buffer.writeln('- Phone: ${profile['phoneNumber'] ?? "NOT SET"}');
                buffer.writeln('- Location: ${profile['location'] ?? "NOT SET"}');
                buffer.writeln('- Type: ${profile['hospitalType'] ?? "NOT SET"}');
                
                // Check for ID fields
                buffer.writeln('');
                buffer.writeln('ID Fields in Profile:');
                buffer.writeln('- healthcare_id: ${profile['healthcare_id'] ?? "NOT SET"}');
                buffer.writeln('- healthcareId: ${profile['healthcareId'] ?? "NOT SET"}');
                buffer.writeln('- _id: ${profile['_id'] ?? "NOT SET"}');
                buffer.writeln('- id: ${profile['id'] ?? "NOT SET"}');
              }
            } catch (e) {
              buffer.writeln('⚠️ Could not parse profile data: $e');
            }
          } else {
            buffer.writeln('❌ Profile NOT FOUND');
            buffer.writeln('Response: ${response.body}');
          }
        } catch (e) {
          buffer.writeln('❌ Error checking profile: $e');
        }
      } else {
        buffer.writeln('=== HEALTHCARE PROFILE CHECK ===');
        buffer.writeln('❌ No healthcare_id in session storage');
        buffer.writeln('Cannot check profile without healthcare_id');
      }

      buffer.writeln('');
      buffer.writeln('=== RECOMMENDATIONS ===');
      
      if (healthcareId == null || healthcareId.isEmpty) {
        buffer.writeln('⚠️ Healthcare ID is not set. You need to:');
        buffer.writeln('   1. Log out');
        buffer.writeln('   2. Log in again');
        buffer.writeln('   3. Complete your hospital profile');
      } else {
        buffer.writeln('✅ Healthcare ID is set');
        buffer.writeln('   You should be able to post jobs if profile exists');
      }

    } catch (e) {
      buffer.writeln('');
      buffer.writeln('❌ DIAGNOSTIC ERROR: $e');
    }

    setState(() {
      diagnosticResult = buffer.toString();
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthcare Diagnostic'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: isRunning ? null : runDiagnostic,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: isRunning
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Running...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text(
                      'Run Diagnostic',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    diagnosticResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
