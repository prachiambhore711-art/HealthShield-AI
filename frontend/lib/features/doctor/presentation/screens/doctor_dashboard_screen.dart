import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/doctor_service.dart';
import 'doctor_profile_screen.dart';
import 'doctor_qr_scanner_screen.dart';
import 'doctor_active_access_screen.dart';
import 'doctor_access_history_screen.dart';
import 'doctor_settings_screen.dart';
import 'doctor_patient_emergency_profile_screen.dart';
import 'doctor_verification_status_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final DoctorService _doctorService = DoctorService();
  bool _isLoading = true;
  String _errorMessage = "";
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _activeSessions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final profileRes = await _doctorService.getDoctorProfile();
    if (!mounted) return;

    if (profileRes["success"]) {
      _profile = profileRes["profile"];
      
      // Cache verification status locally in AuthService
      AuthService.doctorVerificationStatus = _profile!["doctor_verification_status"];

      if (AuthService.doctorVerificationStatus == "verified") {
        final sessions = await _doctorService.getActiveSessions();
        if (mounted) {
          setState(() {
            _activeSessions = sessions;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _activeSessions = [];
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _errorMessage = profileRes["message"];
        _isLoading = false;
      });
    }
  }

  void _showLockMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: AppColors.errorRed),
            SizedBox(width: 8),
            Text("Verification Required", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          "Your account must be verified by the administrator before you can access patient information.",
          style: TextStyle(fontSize: 14, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.deepGreen),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadDashboardData,
                  icon: const Icon(Icons.refresh, color: AppColors.white),
                  label: const Text("Retry", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    foregroundColor: AppColors.white,
                    iconColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final verStatus = _profile?["doctor_verification_status"] ?? "pending";
    final String rawName = _profile?["full_name"] ?? "Doctor";
    final String cleanName = rawName.replaceFirst(RegExp(r'^(dr\.?|doctor)\s+', caseSensitive: false), '').trim();
    final String docName = cleanName.isNotEmpty ? cleanName : rawName;

    final String? storedSpecialty = _profile?["specialization"];
    final String specialty = (storedSpecialty != null && storedSpecialty.trim().isNotEmpty)
        ? storedSpecialty.trim()
        : "General Practitioner";
    final bool isVerified = verStatus == "verified";

    // Setup banner configs if pending/rejected
    Color bannerColor = AppColors.warningOrange;
    String bannerTitle = "Verification Pending";
    String bannerDesc = "Your account is awaiting administrator verification. Patient emergency access will become available after verification.";
    IconData bannerIcon = Icons.hourglass_empty_rounded;

    if (verStatus == "rejected") {
      bannerColor = AppColors.errorRed;
      bannerTitle = "Verification Rejected";
      bannerDesc = "Your professional credentials were rejected. Please check your profile or contact administrator support.";
      bannerIcon = Icons.gpp_bad_outlined;
    } else if (verStatus == "suspended") {
      bannerColor = AppColors.errorRed;
      bannerTitle = "Account Suspended";
      bannerDesc = "Your account access is suspended. Access to patient records is disabled.";
      bannerIcon = Icons.block_flipped;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, Dr. $docName",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
                              color: isVerified ? AppColors.green : AppColors.warningOrange,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                specialty,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
                      ).then((_) => _loadDashboardData());
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.mint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: AppColors.deepGreen,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Verification Status Banner at the Top
              if (!isVerified) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bannerColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: bannerColor.withOpacity(0.3), width: 1.2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(bannerIcon, color: bannerColor, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bannerTitle,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: bannerColor == AppColors.green ? bannerColor : AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bannerDesc,
                              style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 1. Primary Action: Emergency QR Scanner Card
              GestureDetector(
                onTap: () {
                  if (isVerified) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DoctorQrScannerScreen()),
                    ).then((_) => _loadDashboardData());
                  } else {
                    _showLockMessage(context);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: isVerified
                        ? AppColors.doctorGradient
                        : LinearGradient(
                            colors: [Colors.grey.shade400, Colors.grey.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (isVerified ? AppColors.deepGreen : Colors.grey).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isVerified ? Icons.qr_code_scanner_rounded : Icons.lock_outline_rounded,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVerified ? "Scan Emergency QR" : "🔒 Scan Emergency QR",
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isVerified
                                  ? "Access patient critical medical records instantly in an emergency."
                                  : "Available after credential verification by administrators.",
                              style: TextStyle(
                                color: isVerified ? const Color(0xFFE1BEE7) : Colors.grey.shade200,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 2. Active Access Sessions section
              const Text(
                "Active Emergency Access",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              if (!isVerified)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGrey, width: 1.2),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: AppColors.textGrey, size: 36),
                      SizedBox(height: 12),
                      Text(
                        "🔒 Active Access Locked",
                        style: TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Available after account verification",
                        style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (_activeSessions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGrey, width: 1.2),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.textGrey, size: 36),
                      SizedBox(height: 12),
                      Text(
                        "No active patient access sessions",
                        style: TextStyle(color: AppColors.textGrey, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                ..._activeSessions.take(2).map((session) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderGrey, width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session["patient_name"] ?? "Anonymous Patient",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Emergency Authorized Session",
                                style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorPatientEmergencyProfileScreen(accessId: session["id"]),
                              ),
                            ).then((_) => _loadDashboardData());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: const Text("View Profile", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white)),
                        ),
                      ],
                    ),
                  );
                }).toList(),

              const SizedBox(height: 28),

              // 3. Quick Action Shortcuts (2x2 Grid)
              const Text(
                "Shortcuts",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              
              // Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutCard(
                      title: "My Profile",
                      icon: Icons.assignment_ind_outlined,
                      color: AppColors.deepGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShortcutCard(
                      title: "Verification",
                      icon: Icons.verified_user_outlined,
                      color: AppColors.warningOrange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DoctorVerificationStatusScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 2
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutCard(
                      title: "Access Log",
                      icon: Icons.history_rounded,
                      color: AppColors.deepGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DoctorAccessHistoryScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShortcutCard(
                      title: "Settings",
                      icon: Icons.settings_outlined,
                      color: AppColors.deepGreen,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DoctorSettingsScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
