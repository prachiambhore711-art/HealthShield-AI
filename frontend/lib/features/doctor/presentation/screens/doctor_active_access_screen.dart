import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/doctor_service.dart';
import 'doctor_patient_emergency_profile_screen.dart';

class DoctorActiveAccessScreen extends StatefulWidget {
  const DoctorActiveAccessScreen({Key? key}) : super(key: key);

  @override
  State<DoctorActiveAccessScreen> createState() => _DoctorActiveAccessScreenState();
}

class _DoctorActiveAccessScreenState extends State<DoctorActiveAccessScreen> {
  final DoctorService _doctorService = DoctorService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });
    final list = await _doctorService.getActiveSessions();
    if (!mounted) return;
    setState(() {
      _sessions = list;
      _isLoading = false;
    });
  }

  Future<void> _endAccess(int accessId) async {
    final res = await _doctorService.revokeEmergencyAccess(accessId);
    if (!mounted) return;
    if (res["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emergency access closed successfully."), backgroundColor: AppColors.textDark),
      );
      _loadSessions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"]), backgroundColor: AppColors.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Active Access Sessions",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadSessions,
              color: AppColors.deepGreen,
              child: _sessions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.shield_outlined, color: AppColors.textGrey, size: 48),
                              SizedBox(height: 16),
                              Text(
                                "No active emergency access sessions",
                                style: TextStyle(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24.0),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final name = session["patient_name"] ?? "Anonymous Patient";
                        final email = session["patient_email"] ?? "N/A";
                        final grantedAt = session["granted_at"] != null 
                            ? DateTime.parse(session["granted_at"]).toLocal().toString().substring(0, 16)
                            : "N/A";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderGrey, width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                                    child: const Icon(Icons.person_outline_rounded, color: AppColors.deepGreen, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: AppColors.borderGrey),
                              Text("Email: $email", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text("Granted: $grantedAt", style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _endAccess(session["id"]),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.errorRed),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text("End Access", style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DoctorPatientEmergencyProfileScreen(accessId: session["id"]),
                                          ),
                                        ).then((_) => _loadSessions());
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.deepGreen,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text("View Patient", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
