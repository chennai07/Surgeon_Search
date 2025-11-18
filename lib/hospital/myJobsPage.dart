import 'package:flutter/material.dart';
import 'package:doc/hospital/applicants.dart';

class MyJobsPage extends StatefulWidget {
  final VoidCallback? onHospitalNameTap;

  const MyJobsPage({super.key, this.onHospitalNameTap});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  int bottomIndex = 0;
  int tabIndex = 0; // 0 = Active, 1 = Closed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- HEADER CARD ----------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Hospital Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        "assets/logo.png",
                        height: 40,
                        width: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Hospital Name (tappable to go to profile)
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onHospitalNameTap,
                        child: const Text(
                          "Apollo Hospitals",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    // Notification Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.blue,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ---------- SEARCH BAR ----------
              TextField(
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
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => tabIndex = 0),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tabIndex == 0
                                    ? Colors.blue
                                    : const Color(0xffe8f1ff),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Active",
                                style: TextStyle(
                                  color: tabIndex == 0
                                      ? Colors.white
                                      : Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => tabIndex = 1),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tabIndex == 1
                                    ? Colors.blue
                                    : const Color(0xffe8f1ff),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Closed",
                                style: TextStyle(
                                  color: tabIndex == 1
                                      ? Colors.white
                                      : Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "0 Results",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // ---------- EMPTY JOBS CARD ----------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "No job openings yet",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Start hiring by posting your first job.",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Applicants(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Post a Job"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ---------- BOTTOM NAVIGATION ----------
    );
  }
}
  // Custom Bottom Navigation
  