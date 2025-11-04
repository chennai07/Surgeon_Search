import 'dart:convert';                                                                    User Profile Code flutter
import 'dart:io';
import 'package:doc/model/api_service.dart';
import 'package:doc/profileprofile/profile.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfessionalProfilePage extends StatefulWidget {
  const ProfessionalProfilePage({super.key});

  @override
  State<ProfessionalProfilePage> createState() =>
      _ProfessionalProfilePageState();
}

class _ProfessionalProfilePageState extends State<ProfessionalProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController specialityController = TextEditingController();
  final TextEditingController subSpecialityController = TextEditingController();
  final TextEditingController summaryController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController organizationController = TextEditingController();
  final TextEditingController fromYearController = TextEditingController();
  final TextEditingController toYearController = TextEditingController();

  File? _image;
  File? _cvFile;
  bool _isLoading = false;

  // ✅ Image picker
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) setState(() => _image = File(pickedFile.path));
  }

  // ✅ CV picker
  Future<void> _pickCV() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) setState(() => _cvFile = File(pickedFile.path));
  }

  // ✅ Date picker (ensures valid YYYY-MM-DD format)
  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  // ✅ Submit Profile
  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ApiService.createProfile(
      fullName: fullNameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
      location: locationController.text.trim(),
      degree: degreeController.text.trim(),
      speciality: specialityController.text.trim(),
      subSpeciality: subSpecialityController.text.trim(),
      summaryProfile: summaryController.text.trim(),
      termsAccepted: true,
      profileId: "6901b118dcca2b9cc4636e9d", // ✅ use your real profile ID
      portfolioLinks: "linkkk",
      workExperience: [
        {
          "designation": designationController.text.trim(),
          "healthcareOrganization": organizationController.text.trim(),
          "from": fromYearController.text.trim(),
          "to": toYearController.text.trim(),
          "location": locationController.text.trim(),
        },
      ],
      imageFile: _image,
      cvFile: _cvFile,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final data = result['data'];
      final newProfileId = data['profile']?['_id'] ?? data['_id'] ?? data['id'];

      if (newProfileId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_id', newProfileId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Profile Created: $newProfileId')),
        );

        // ✅ Navigate to DoctorProfilePage immediately
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorProfilePage(
              initialProfileJson: jsonEncode(data['profile'] ?? data),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Profile ID missing in response')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed: ${result['message']}')));
    }
  }

  // ✅ Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    text: "Professional ",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
                    children: [
                      TextSpan(
                        text: "profile",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildInputField(Iconsax.user, "Full Name", fullNameController),
                _buildInputField(Iconsax.call, "Phone number", phoneController),
                _buildInputField(Iconsax.sms, "Email", emailController),
                _buildInputField(
                  Iconsax.location,
                  "Location",
                  locationController,
                ),

                const SizedBox(height: 20),
                _buildLabel("Your Profile Picture"),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            "Upload your image",
                            style: TextStyle(color: Colors.black45),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 15),
                          child: Icon(Iconsax.export, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: FileImage(_image!),
                      ),
                    ),
                  ),

                _buildLabel("Degree"),
                _buildContainerField("Your Degree", degreeController),
                _buildLabel("Speciality"),
                _buildContainerField("Your Speciality", specialityController),
                _buildLabel("Sub-speciality"),
                _buildContainerField(
                  "Your Sub-speciality",
                  subSpecialityController,
                ),
                _buildLabel("Summary profile"),
                _buildContainerField(
                  "Tell about yourself",
                  summaryController,
                  maxLines: 4,
                ),

                _buildLabel("Work experience"),
                _buildContainerField("Designation", designationController),
                _buildContainerField(
                  "Healthcare Organization",
                  organizationController,
                ),

                _buildLabel("Year"),
                Row(
                  children: [
                    _buildDateBox("From", fromYearController),
                    _buildDateBox("To", toYearController),
                  ],
                ),

                const SizedBox(height: 30),
                _buildLabel("Upload CV (PDF)"),
                GestureDetector(
                  onTap: _pickCV,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            "Upload your CV",
                            style: TextStyle(color: Colors.black45),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 15),
                          child: Icon(
                            Iconsax.document_upload,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB3E5FC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submitProfile,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Submit",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Reusable UI
  Widget _buildInputField(
    IconData icon,
    String hint,
    TextEditingController c,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black45, size: 20),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 18,
          ),
        ),
      ),
    ),
  );

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 15),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
    ),
  );

  Widget _buildContainerField(
    String hint,
    TextEditingController c, {
    int maxLines = 1,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black26),
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint, border: InputBorder.none),
    ),
  );

  Widget _buildDateBox(String label, TextEditingController c) => Expanded(
    child: GestureDetector(
      onTap: () => _selectDate(c),
      child: AbsorbPointer(
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black26),
          ),
          child: TextField(
            controller: c,
            decoration: InputDecoration(
              prefixIcon: const Icon(Iconsax.calendar_1, size: 18),
              hintText: label == "From"
                  ? "Select start date"
                  : "Select end date",
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    ),
  );
}
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                                                                                                 Sigin code 


import 'dart:convert'; // ✅ For JSON encoding/decoding
import 'package:doc/profileprofile/professional_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Import your Professional Profile Page

// ↑ Replace the above path with your actual file path if different

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

  // ✅ API CALL FUNCTION
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

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Login Response: $data');

        // ✅ Extract token and profile/user id
        final token = data['token'];
        final userData = data['user'] ?? data['profile'] ?? data;
        final profileId = userData['_id'] ?? userData['profile_id'];

        if (profileId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_id', profileId.toString());
          print('✅ Saved profile_id: $profileId');
        } else {
          print('⚠️ No profile_id found in response.');
        }

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token.toString());
          print('🔑 Token saved: $token');
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Login Successful!')));

        // ✅ Navigate to ProfessionalProfilePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfessionalProfilePage(),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${error['message'] ?? 'Invalid credentials'}'),
          ),
        );
        print('❌ Login failed: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      print('⚠️ Exception during login: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text.rich(
                TextSpan(
                  text: "Let’s ",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
                  children: [
                    TextSpan(
                      text: "Sign In",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // ✅ Logo
              Center(child: Image.asset('assets/logo2.png', height: 150)),
              const SizedBox(height: 60),

              // ✅ Email Field
              TextField(
                controller: _emailController,
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

              // ✅ Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Iconsax.lock, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Iconsax.eye_slash : Iconsax.eye),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
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

              // ✅ Sign In Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB3E5FC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
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
              const SizedBox(height: 15),

              // ✅ Forgot password & Sign up
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        "Don’t have an account?",
                        style: TextStyle(color: Colors.black87, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to Sign Up Page
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF003366),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



                                                                                                      Profile Code
                                                                                                      
 import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileView extends StatefulWidget {
  final String profileId;
  const ProfileView({super.key, required this.profileId});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool isLoading = true;
  Map<String, dynamic>? profileData;

  @override
  void initState() {
    super.initState();
    fetchProfileInfo();
  }

  // --- Utility for Date Formatting ---
  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${months[date.month - 1]} ${date.year}";
    } catch (_) {
      // Fallback to showing only the date part if parsing fails
      return isoDate.split("T").first;
    }
  }
  // ------------------------------------

  Future<void> fetchProfileInfo() async {
    final String apiUrl =
        "https://surgeon-search.onrender.com/api/sugeon/profile-info/${widget.profileId}";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      debugPrint("Profile API status: ${response.statusCode}");
      debugPrint("Profile API body: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['data'] != null) {
          setState(() {
            profileData = json['data'] as Map<String, dynamic>;
            isLoading = false;
          });
        } else {
          // Profile exists but no data, or data structure is unexpected
          setState(() {
            profileData = {};
            isLoading = false;
          });
        }
      } else {
        // Explicitly handle non-200 status codes (like 404) by setting data to empty
        setState(() {
          profileData = {};
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("fetchProfileInfo error: $e");
      setState(() {
        profileData = {}; // Explicitly handle network/parsing errors
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profileData == null || profileData!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile Not Found"),
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              Text(
                "Profile with ID: ${widget.profileId} not found.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Safely extract data
    final name = profileData!["fullName"] ?? "Unknown Surgeon";
    final location = profileData!["location"] ?? "N/A";
    final speciality = profileData!["speciality"] ?? "N/A";
    final subSpeciality = profileData!["subSpeciality"] ?? "N/A";
    final degree = profileData!["degree"] ?? "N/A";
    final summary = profileData!["summaryProfile"] ?? "No summary provided.";
    final email = profileData!["email"] ?? "N/A";
    final phone = profileData!["phoneNumber"] ?? "N/A";
    final portfolio = profileData!["portfolioLinks"] ?? "";
    final experiences = (profileData!["workExperience"] ?? []) as List<dynamic>;

    // Placeholder image URL for demonstration (replace with actual field later)
    final profileImageUrl =
        profileData!["profilePicture"] ??
        "https://placehold.co/100x100/ADD8E6/000000?text=Dr";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Surgeon Profile"),
        backgroundColor: Colors.lightBlueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Card (Name, Speciality, Image) ---
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.lightBlueAccent.withOpacity(0.5),
                      backgroundImage: profileImageUrl.startsWith('http')
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl.startsWith('http')
                          ? null
                          : const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$speciality ($subSpeciality)",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Degree: $degree",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Contact & Links Card ---
            _buildSectionCard(
              title: "Contact & Location",
              icon: Icons.contact_mail,
              children: [
                _buildInfoTile("Location", location, Icons.location_on),
                _buildInfoTile("Email", email, Icons.email),
                _buildInfoTile("Phone", phone, Icons.phone),
                if (portfolio.isNotEmpty)
                  _buildInfoTile(
                    "Portfolio",
                    portfolio,
                    Icons.link,
                    isLink: true,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Summary/About Card ---
            _buildSectionCard(
              title: "Professional Summary",
              icon: Icons.info,
              children: [
                Text(
                  summary,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Experience Card ---
            _buildSectionCard(
              title: "Work Experience",
              icon: Icons.work,
              children: [
                if (experiences.isEmpty)
                  const Text("No work experience added.")
                else
                  ...experiences.map((e) => _buildExperienceCard(e)).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Section Card (Contact, Summary, Experience)
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.lightBlueAccent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  // Helper for contact/info rows
  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon, {
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: isLink ? Colors.lightBlueAccent : Colors.black54,
                    decoration: isLink
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for displaying a single Work Experience entry
  Widget _buildExperienceCard(dynamic experience) {
    final title = experience['designation'] ?? 'N/A';
    final org = experience['healthcareOrganization'] ?? 'N/A';
    final loc = experience['location'] ?? 'N/A';
    final from = _formatDate(experience['from']);
    final to = _formatDate(experience['to']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              org,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            Text(
              loc,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            Text(
              "$from - $to",
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.lightBlueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}













                                                                                                 
