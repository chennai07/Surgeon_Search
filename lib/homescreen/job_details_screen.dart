import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/colors.dart';

void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔵 Title Row (Clean & Identical to Screenshot)
              Row(
                children: const [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Application Submitted",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ✨ Message Texts
              const Text(
                "Thank you for applying!",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your job has been saved under 'Applied Jobs'.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

              const SizedBox(height: 25),

              /// 🔘 OK Button (Right-aligned like screenshot)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _job;

  @override
  void initState() {
    super.initState();
    _fetchJobDetails();
  }

  Future<void> _fetchJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = Uri.parse(
          'https://surgeon-search.onrender.com/api/healthcare/job-profile/${widget.jobId}');
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

        Map<String, dynamic> jobMap = <String, dynamic>{};
        if (data is Map) {
          jobMap = Map<String, dynamic>.from(data as Map);
        }

        setState(() {
          _job = jobMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load job details (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading job details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Job Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : _job == null
                  ? const Center(child: Text('Job not found'))
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_job!['jobTitle'] ?? '').toString(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (_job!['healthcareName'] ??
                                    _job!['hospitalName'] ??
                                    '')
                                .toString(),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (_job!['location'] ?? '').toString(),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),

                          // Meta info chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if ((_job!['jobType'] ?? '').toString().isNotEmpty)
                                _chip((_job!['jobType'] ?? '').toString()),
                              if ((_job!['department'] ?? '').toString().isNotEmpty)
                                _chip((_job!['department'] ?? '').toString()),
                              if ((_job!['subSpeciality'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                _chip((_job!['subSpeciality'] ?? '').toString()),
                              if ((_job!['salaryRange'] ?? '').toString().isNotEmpty)
                                _chip((_job!['salaryRange'] ?? '').toString()),
                            ],
                          ),

                          const SizedBox(height: 24),
                          _sectionTitle('About Role'),
                          _sectionBody(
                              (_job!['aboutRole'] ?? '').toString().trim()),

                          const SizedBox(height: 16),
                          _sectionTitle('Key Responsibilities'),
                          _sectionBody((_job!['keyResponsibilities'] ?? '')
                              .toString()
                              .trim()),

                          const SizedBox(height: 16),
                          _sectionTitle('Preferred Qualifications'),
                          _sectionBody((_job!['preferredQualifications'] ?? '')
                              .toString()
                              .trim()),

                          const SizedBox(height: 16),
                          _sectionTitle('Experience Required'),
                          _sectionBody(
                              'Minimum ${( _job!['minYearsOfExperience'] ?? '').toString()} years'),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => _showSuccessDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Apply Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFD6EDFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _sectionBody(String text) {
    if (text.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text(
          'Not specified',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }
}
