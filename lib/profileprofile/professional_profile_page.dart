import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ProfessionalProfileViewPage extends StatefulWidget {
  final String profileId;
  const ProfessionalProfileViewPage({super.key, required this.profileId});

  @override
  State<ProfessionalProfileViewPage> createState() =>
      _ProfessionalProfileViewPageState();
}

class _ProfessionalProfileViewPageState
    extends State<ProfessionalProfileViewPage> {
  bool isLoading = true;
  Map<String, dynamic>? profileData;
  String? token;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final url = Uri.parse(
        "https://surgeon-search.onrender.com/api/sugeon/profile/${widget.profileId}",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          profileData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        Get.snackbar("Error", "Failed to load profile");
        setState(() => isLoading = false);
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong: $e");
      setState(() => isLoading = false);
    }
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value, IconData icon) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),
        subtitle: Text(
          value ?? "Not provided",
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _fileCard(String title, String? url, IconData icon) {
    bool isImageUrl =
        url != null &&
        (url.endsWith(".jpg") || url.endsWith(".jpeg") || url.endsWith(".png"));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: url == null || url.isEmpty
            ? const Text("No file uploaded")
            : GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    Get.snackbar("Error", "Cannot open file");
                  }
                },
                child: Text(
                  isImageUrl ? "View Image" : "Open File",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final data = profileData ?? {};

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Professional Profile",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Basic Information", Iconsax.user),
            _infoRow("Full Name", data['fullName'], Iconsax.user),
            _infoRow("Phone Number", data['phoneNumber'], Iconsax.call),
            _infoRow("Email", data['email'], Iconsax.sms),
            _infoRow("Location", data['location'], Iconsax.location),

            _sectionTitle("Professional Details", Iconsax.briefcase),
            _infoRow("Degree", data['degree'], Iconsax.book),
            _infoRow("Speciality", data['speciality'], Iconsax.hospital),
            _infoRow("Sub Speciality", data['subSpeciality'], Iconsax.activity),
            _infoRow(
              "Years of Experience",
              data['yearsOfExperience']?.toString(),
              Iconsax.timer,
            ),
            _infoRow(
              "Surgical Experience",
              data['surgicalExperience'],
              Iconsax.medal_star,
            ),

            _sectionTitle("Portfolio & Summary", Iconsax.note),
            _infoRow("Portfolio Links", data['portfolioLinks'], Iconsax.link),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      Icons.format_align_justify,
                      color: Colors.blueAccent,
                    ),
                    title: const Text("Summary Profile"),
                    subtitle: Text(
                      data['summaryProfile'] ?? "No summary provided",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                title: const Text("Summary Profile"),
                subtitle: Text(
                  data['summaryProfile'] ?? "No summary provided",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            _sectionTitle("Attachments", Iconsax.document),
            _fileCard(
              "Profile Picture",
              data['profilePicture'],
              Iconsax.user_square,
            ),
            _fileCard("CV", data['cv'], Iconsax.document),
            _fileCard("Highest Degree", data['highestDegree'], Iconsax.book),
            _fileCard(
              "Upload LogBook",
              data['uploadLogBook'],
              Iconsax.folder_open,
            ),

            const SizedBox(height: 25),
            Center(
              child: ElevatedButton.icon(
                onPressed: () =>
                    Get.toNamed('/editProfile', arguments: widget.profileId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Iconsax.edit, color: Colors.white),
                label: Text(
                  "Edit Profile",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
