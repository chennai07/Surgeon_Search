import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:doc/utils/session_manager.dart';
import 'package:doc/utils/colors.dart';
import 'package:doc/homescreen/SearchjobScreen.dart';
import 'package:doc/profileprofile/surgeon_profile.dart';

class AppliedJobsScreen extends StatefulWidget {
  const AppliedJobsScreen({super.key});

  @override
  State<AppliedJobsScreen> createState() => _AppliedJobsScreenState();
}

class _AppliedJobsScreenState extends State<AppliedJobsScreen> {
  List<Map<String, dynamic>> appliedJobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
  }

  /// 🔹 Load applied jobs from backend for current user/profile
  Future<void> _loadAppliedJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileId = await SessionManager.getProfileId();
      if (profileId == null || profileId.isEmpty) {
        setState(() {
          _error = 'Profile id not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse(
          'http://13.203.67.154:3000/api/jobs/applied-jobs/$profileId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final body = response.body.trimLeft();
        dynamic decoded;
        try {
          decoded = jsonDecode(body);
        } catch (_) {
          decoded = {};
        }

        final data = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;
        final list = data is List
            ? data
            : (data is Map && data['jobs'] is List ? data['jobs'] : <dynamic>[]);

        final jobs = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is! Map) continue;
          final m = item;

          // A lot of applied-jobs APIs nest the job data inside a 'job' or 'jobProfile' key.
          final rawJob = m['job'] is Map
              ? m['job'] as Map
              : (m['jobProfile'] is Map
                  ? m['jobProfile'] as Map
                  : m);

          // Try to derive a readable applied date from the wrapper object
          final rawDate = m['appliedAt'] ?? m['createdAt'] ?? m['updatedAt'] ?? '';
          String dateLabel = '';
          if (rawDate is String && rawDate.isNotEmpty) {
            try {
              final dt = DateTime.parse(rawDate);
              dateLabel = dt.toLocal().toString().split(' ').first;
            } catch (_) {
              dateLabel = rawDate.toString();
            }
          }

          jobs.add({
            'title': rawJob['jobTitle']?.toString() ??
                rawJob['title']?.toString() ??
                rawJob['role']?.toString() ??
                rawJob['position']?.toString() ??
                '',
            'org': rawJob['healthcareName']?.toString() ??
                rawJob['hospitalName']?.toString() ??
                rawJob['healthcareOrganization']?.toString() ??
                '',
            'location': rawJob['location']?.toString() ?? '',
            'date': dateLabel,
          });
        }

        setState(() {
          appliedJobs = jobs;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        // No applied jobs found for this user/profile
        setState(() {
          appliedJobs = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load applied jobs (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading applied jobs: $e';
        _isLoading = false;
      });
    }
  }

  /// 🔹 Show confirmation dialog before deleting
  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        title: const Text(
          "Remove Job?",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: const Text(
          "Are you sure you want to remove this job from your applied jobs list?",
          style: TextStyle(
            height: 1.4,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
        actions: [
          /// CANCEL BUTTON
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),

          /// DELETE BUTTON
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteJob(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              "Remove",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Delete a specific job
  Future<void> _deleteJob(int index) async {
    // For now, just remove from the local list (no backend delete endpoint provided)
    setState(() {
      appliedJobs.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Job removed 🗑️"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Applied Jobs"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.close_circle,
                          color: Colors.redAccent,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadAppliedJobs,
                          icon: const Icon(Iconsax.refresh, size: 18),
                          label: const Text("Retry"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : appliedJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.document,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No applied jobs yet 📝",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Start applying to jobs to see them here",
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: appliedJobs.length,
                      itemBuilder: (context, index) {
                        final job = appliedJobs[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Job Info
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// Logo/Icon
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor:
                                          AppColors.primary.withOpacity(0.1),
                                      child: const Icon(
                                        Iconsax.briefcase,
                                        color: AppColors.primary,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    /// Job Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            job['title'] ?? 'Unknown Role',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            job['org'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                Iconsax.location,
                                                size: 14,
                                                color: Colors.black54,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  job['location'] ?? '',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    /// Delete Button
                                    IconButton(
                                      icon: const Icon(
                                        Iconsax.trash,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => _showDeleteDialog(index),
                                    ),
                                  ],
                                ),

                                /// Applied Date
                                if (job['date'] != null &&
                                    job['date'].toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 68,
                                      top: 8,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Iconsax.tick_circle,
                                            size: 14,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Applied on ${job['date']}",
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomNavItem(Iconsax.search_normal, "Search", false, () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              );
            }),
            _bottomNavItem(Iconsax.document, "Applied Jobs", true, () {
              // Already on applied jobs; no action
            }),
            _bottomNavItem(Iconsax.user, "Profile", false, () async {
              final profileId = await SessionManager.getProfileId();
              if (!mounted) return;
              if (profileId == null || profileId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Profile not found. Please complete your profile.'),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfessionalProfileViewPage(
                    profileId: profileId,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Item (same visual style as other screens)
  Widget _bottomNavItem(
      IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isActive ? Colors.blue : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
