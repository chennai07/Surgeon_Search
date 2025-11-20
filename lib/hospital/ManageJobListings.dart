import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/hospital/JobDetailsScreen.dart';

class ManageJobListings extends StatefulWidget {
  const ManageJobListings({super.key});

  @override
  State<ManageJobListings> createState() => _ManageJobListingsState();
}

class _ManageJobListingsState extends State<ManageJobListings> {
  int tabIndex = 0;

  // ---------- JOBS (mock data) ----------
  final List<Map<String, dynamic>> jobs = [
    {
      "id": "JD003",
      "title": "Consultant Neurosurgeon",
      "status": "Active",
      "department": "Neurosurgery",
      "specialization": "Spinal Surgery",
      "experience": "5+ years",
      "deadline": "17-Nov-2025",
      "applicants": 3,
      "type": "Full time",
      "location": "Bangalore",
      "ago": "5 days ago",
    },
    {
      "id": "JD0123",
      "title": "Consultant Neurosurgeon - Night Shift",
      "status": "Active",
      "department": "Neurosurgery",
      "specialization": "Spinal Surgery",
      "experience": "7+ years",
      "deadline": "20-Nov-2025",
      "applicants": 1,
      "type": "Full time",
      "location": "Chennai",
      "ago": "2 days ago",
    },
    {
      "id": "JD004",
      "title": "Associate Neurosurgeon",
      "status": "Closed",
      "department": "Neurosurgery",
      "specialization": "Brain Tumor",
      "experience": "3+ years",
      "deadline": "01-Nov-2025",
      "applicants": 5,
      "type": "Part time",
      "location": "Bangalore",
      "ago": "15 days ago",
    },
  ];

  // ---------- APPLICANTS BY JOB ID (mock data) ----------
  final Map<String, List<Map<String, dynamic>>> applicantsByJobId = {
    "JD003": [
      {
        "id": "A001",
        "name": "Dr. Rajesh Kumar",
        "experience": "6 years",
        "appliedOn": "10-Nov-2025",
        "status": "New",
        "resume": "Resume.pdf",
      },
      {
        "id": "A002",
        "name": "Dr. Meera Nair",
        "experience": "8 years",
        "appliedOn": "11-Nov-2025",
        "status": "Shortlisted",
        "resume": "Resume.pdf",
      },
      {
        "id": "A003",
        "name": "Dr. Arjun Bala",
        "experience": "5 years",
        "appliedOn": "12-Nov-2025",
        "status": "Rejected",
        "resume": "Resume.pdf",
      },
    ],
    "JD0123": [
      {
        "id": "A004",
        "name": "Dr. Kavya R",
        "experience": "7 years",
        "appliedOn": "13-Nov-2025",
        "status": "New",
        "resume": "Resume.pdf",
      },
    ],
    "JD004": [
      {
        "id": "A005",
        "name": "Dr. Sandeep",
        "experience": "4 years",
        "appliedOn": "20-Oct-2025",
        "status": "New",
        "resume": "Resume.pdf",
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    // filter jobs by tab index (0 -> Active, 1 -> Closed)
    final List<Map<String, dynamic>> filteredJobs = jobs
        .where(
          (j) =>
              tabIndex == 0 ? j["status"] == "Active" : j["status"] == "Closed",
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- TOP HEADER ----------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // keep asset image path same as yours
                    Image.asset(
                      "assets/logo.png",
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Apollo Hospitals",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------- SEARCH BAR ----------
              TextField(
                onChanged: (val) {
                  // For brevity, search is not implemented in this example.
                  // You can filter `jobs` based on `val` here.
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: "Search",
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------- FILTER + ACTIVE/CLOSED ----------
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.filter_alt, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        _tabButton(index: 0, text: "Active"),
                        const SizedBox(width: 10),
                        _tabButton(index: 1, text: "Closed"),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                "${filteredJobs.length} Results",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 16),

              // ---------- JOB LIST ----------
              Column(
                children: filteredJobs.map((job) => _jobCard(job)).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewApplicantsForJob(Map<String, dynamic> job) async {
    final rawId = job['_id'] ?? job['id'] ?? '';
    final jobId = rawId.toString();
    if (jobId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job id not found for this listing.')),
      );
      return;
    }

    try {
      final uri = Uri.parse(
        'http://13.203.67.154:3000/api/jobs/applied-jobs/specific-jobs/$jobId',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = response.body.trimLeft();
        dynamic decoded;
        try {
          decoded = jsonDecode(body);
        } catch (_) {
          decoded = [];
        }

        final data = decoded is Map && decoded['data'] != null
            ? decoded['data']
            : decoded;
        final list = data is List
            ? data
            : (data is Map && data['applications'] is List
                ? data['applications']
                : <dynamic>[]);

        final applicants = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is! Map) continue;
          final m = item;
          final rawApplicant = m['applicant'] is Map
              ? m['applicant'] as Map
              : m;
          applicants.add(Map<String, dynamic>.from(rawApplicant as Map));
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ApplicantsListPage(
              jobId: jobId,
              applicants: applicants,
            ),
          ),
        );
      } else if (response.statusCode == 404) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No applicants found for this job.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load applicants (${response.statusCode})',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading applicants: $e')),
      );
    }
  }

  // ----------- Active / Closed Tab Button ----------
  Widget _tabButton({required int index, required String text}) {
    final bool isSelected = tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tabIndex = index),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : const Color(0xffe8f1ff),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ----------- JOB CARD ----------
  Widget _jobCard(Map<String, dynamic> job) {
    return GestureDetector(
      onTap: () {
        // navigate to detail and pass callbacks to modify state
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(
              job: job,
              onEdit: (updated) {
                // update job in list
                setState(() {
                  final idx = jobs.indexWhere((j) => j['id'] == job['id']);
                  if (idx != -1) jobs[idx] = {...jobs[idx], ...updated};
                });
              },
              onClose: () {
                setState(() {
                  final idx = jobs.indexWhere((j) => j['id'] == job['id']);
                  if (idx != -1) jobs[idx]['status'] = 'Closed';
                });
              },
              onDelete: () {
                setState(() {
                  jobs.removeWhere((j) => j['id'] == job['id']);
                });
                Navigator.pop(context); // close detail page after delete
              },
              onViewApplicants: () {
                _viewApplicantsForJob(job);
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: "Job ID: ",
                    style: const TextStyle(color: Colors.black87),
                    children: [
                      TextSpan(
                        text: job["id"],
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(job["ago"], style: const TextStyle(color: Colors.black54)),
              ],
            ),

            const SizedBox(height: 10),

            // Logo + Title + Status
            Row(
              children: [
                Image.asset("assets/logo.png", height: 36, width: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job["title"],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        job["status"],
                        style: TextStyle(
                          fontSize: 13,
                          color: job["status"] == "Active"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text("Department: ${job["department"]}"),
            Text("Specialization: ${job["specialization"]}"),
            Text("Experience: ${job["experience"]}"),

            const SizedBox(height: 8),

            Text(
              "Application Deadline: ${job["deadline"]}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                _chip(Icons.group, "${job["applicants"]} Applicants"),
                const SizedBox(width: 10),
                _chip(Icons.access_time_filled, job["type"]),
                const SizedBox(width: 10),
                _chip(Icons.location_on, job["location"]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ----------- BOTTOM TAGS (APPLICANTS / FULL TIME / LOCATION) ----------
  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xffe8f1ff),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.blue, fontSize: 13)),
        ],
      ),
    );
  }
}
