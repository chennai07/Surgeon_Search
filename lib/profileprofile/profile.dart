import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class DoctorProfilePage extends StatefulWidget {
  final String profileId;
  const DoctorProfilePage({super.key, required this.profileId});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  bool isLoading = true;
  Map<String, dynamic>? profileData;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    await _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication token missing")),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      final url = Uri.parse(
        'https://surgeon-search.onrender.com/api/sugeon/profile/${widget.profileId}',
      ); // Change this endpoint if backend differs
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profileData = data;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error fetching profile: ${response.statusCode}"),
          ),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Exception: $e")));
      setState(() => isLoading = false);
    }
  }

  Widget _buildField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          Expanded(child: Text(value ?? "-", style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileData == null
          ? Center(
              child: Text(
                "No profile data found",
                style: GoogleFonts.poppins(),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField("Full Name", profileData!['fullName']),
                  _buildField("Email", profileData!['email']),
                  _buildField("Phone Number", profileData!['phoneNumber']),
                  _buildField("Location", profileData!['location']),
                  _buildField("Degree", profileData!['degree']),
                  _buildField("Speciality", profileData!['speciality']),
                  _buildField("Sub-Speciality", profileData!['subSpeciality']),
                  _buildField(
                    "Summary Profile",
                    profileData!['summaryProfile'],
                  ),
                  _buildField(
                    "Years of Experience",
                    profileData!['yearsOfExperience']?.toString(),
                  ),
                  _buildField(
                    "Surgical Experience",
                    profileData!['surgicalExperience'],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Uploaded Documents",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  if (profileData!['profilePictureUrl'] != null)
                    Image.network(profileData!['profilePictureUrl']),
                  if (profileData!['cvUrl'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton.icon(
                        icon: const Icon(Iconsax.document),
                        label: const Text("View CV"),
                        onPressed: () {
                          // ! Launch/view logic (e.g., open in browser or download)
                        },
                      ),
                    ),
                  if (profileData!['highestDegreeUrl'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton.icon(
                        icon: const Icon(Iconsax.document),
                        label: const Text("View Highest Degree"),
                        onPressed: () {
                          // Launch/view
                        },
                      ),
                    ),
                  if (profileData!['uploadLogBookUrl'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextButton.icon(
                        icon: const Icon(Iconsax.document_upload),
                        label: const Text("View Log Book"),
                        onPressed: () {
                          // Launch/view
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
