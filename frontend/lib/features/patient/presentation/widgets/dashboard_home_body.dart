import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/colors.dart';
import '../../../../features/auth/data/auth_service.dart';
import '../../data/patient_service.dart';
import '../../presentation/screens/emergency_qr_screen.dart';
import '../../presentation/screens/emergency_access_screen.dart';
import '../../presentation/screens/medical_profile_screen.dart';
import '../../presentation/screens/medical_reports_screen.dart';
import '../../presentation/screens/emergency_contacts_screen.dart';
import '../../presentation/screens/patient_profile_screen.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart';
import 'package:frontend/features/patient/presentation/screens/settings_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/reminders_screen.dart';

class DashboardHomeBody extends StatelessWidget {
  const DashboardHomeBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String patientName = AuthService.userFullName ?? "Patient";

    return AuthBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Personalized greeting/header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "HealthShield AI",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Hello, $patientName 👋",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          "Your premium health dashboard",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderGrey, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        color: AppColors.textDark,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Emergency QR Access - HIGHLY VISIBLE
              const Text(
                "Emergency QR Access",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmergencyQrScreen(isNavigatedFromNavBar: false),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.green.withOpacity(0.3), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          color: AppColors.deepGreen,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Emergency QR Shield",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepGreen,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "Tap to open your secure profile QR for paramedics & emergency doctors.",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.deepGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.deepGreen,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDashboardCard(
                      context: context,
                      title: "Access Control",
                      subtitle: "Scanning requests",
                      icon: Icons.security_rounded,
                      iconColor: AppColors.green,
                      iconBg: const Color(0xFFE6FDF4),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmergencyAccessScreen(isNavigatedFromNavBar: false),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDashboardCard(
                      context: context,
                      title: "Pill Reminders",
                      subtitle: "Medication alerts",
                      icon: Icons.medication_rounded,
                      iconColor: AppColors.deepGreen,
                      iconBg: AppColors.mint,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RemindersScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // One-Tap SOS Action
              Material(
                color: AppColors.softEmergencyBg,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => _triggerSOS(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.errorRed.withOpacity(0.35), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.errorRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sos_rounded, color: AppColors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "One-Tap Emergency SOS",
                                style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Opens pre-filled emergency SMS composer with GPS",
                                style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.send_rounded, color: AppColors.errorRed, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 3. AI Health Assistant - MAJOR FEATURE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.aiGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.premiumPink.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "AI Health Assistant",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Intelligent",
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      "Ask wellness questions, calculate body mass index, or search nearby clinical providers.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.lightestPink,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.premiumPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AIAssistantScreen()),
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.premiumPink),
                          SizedBox(width: 8),
                          Text(
                            "Chat with AI Helper",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Health Summary & Quick Actions
              const Text(
                "Health Summary & Tools",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionRow(
                context,
                title: "Medical Profile",
                subtitle: "Blood group, conditions, meds",
                icon: Icons.favorite_rounded,
                color: AppColors.green,
                targetScreen: const MedicalProfileScreen(isNavigatedFromNavBar: false),
              ),
              const SizedBox(height: 12),
              _buildQuickActionRow(
                context,
                title: "Medical Reports",
                subtitle: "Manage uploaded test files",
                icon: Icons.folder_shared_rounded,
                color: AppColors.deepGreen,
                targetScreen: const MedicalReportsScreen(),
              ),
              const SizedBox(height: 12),
              _buildQuickActionRow(
                context,
                title: "Medication Reminders",
                subtitle: "Daily pill schedules & alerts",
                icon: Icons.medication_rounded,
                color: AppColors.green,
                targetScreen: const RemindersScreen(),
              ),
              const SizedBox(height: 12),
              _buildQuickActionRow(
                context,
                title: "Emergency Contacts",
                subtitle: "Trusted family relationships",
                icon: Icons.contact_phone_rounded,
                color: AppColors.pink,
                targetScreen: const EmergencyContactsScreen(),
              ),
              const SizedBox(height: 12),
              _buildQuickActionRow(
                context,
                title: "Personal Account Info",
                subtitle: "Name, email, phone configuration",
                icon: Icons.badge_rounded,
                color: AppColors.textGrey,
                targetScreen: const PatientProfileScreen(isNavigatedFromNavBar: false),
              ),
              const SizedBox(height: 24),

              // Security Protection Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stay Protected",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Your health records are encrypted locally and backed up securely.",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _triggerSOS(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.errorRed),
      ),
    );

    try {
      Position? position;
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          // 1. Try immediate last known position first as fallback
          try {
            position = await Geolocator.getLastKnownPosition();
          } catch (_) {}

          // 2. Attempt fresh high-accuracy position with 10s timeout
          try {
            final freshPos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 10),
            );
            position = freshPos;
          } catch (_) {
            // Keep last known position if fresh timed out
          }
        }
      } catch (locErr) {
        debugPrint("[SOS_DEBUG] Location error: $locErr");
      }

      final patientService = PatientService();
      final contacts = await patientService.getEmergencyContacts();
      Map<String, dynamic>? primary;
      if (contacts.isNotEmpty) {
        primary = contacts.firstWhere((c) => c['is_primary'] == true, orElse: () => contacts.first);
      }

      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Dismiss loading dialog
      }

      final patientName = AuthService.userFullName ?? "HealthShield User";
      final lat = position?.latitude ?? 0.0;
      final lng = position?.longitude ?? 0.0;
      final mapsUrl = position != null
          ? "https://maps.google.com/?q=$lat,$lng"
          : "Location unavailable (GPS offline)";

      final message = "EMERGENCY ALERT — HealthShield AI:\n"
          "$patientName may need immediate assistance!\n\n"
          "Current GPS Location:\n$mapsUrl\n\n"
          "Please contact or locate them immediately.";

      if (!context.mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.errorRed),
              SizedBox(width: 8),
              Text("Emergency SOS Alert", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary != null
                    ? "Pre-filling emergency SMS for: ${primary['name']} (${primary['phone_number']})"
                    : "No emergency contact configured yet! You can share this alert directly.",
                style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey, height: 1.3),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.send_rounded, color: AppColors.white, size: 16),
              label: const Text("Open SMS Composer", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );

      if (proceed == true) {
        final phone = primary?['phone_number'] ?? '';
        final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
        final Uri smsUri = Uri(
          scheme: 'sms',
          path: cleanPhone,
          queryParameters: message.isNotEmpty ? <String, String>{'body': message} : null,
        );

        bool launched = false;
        try {
          if (await canLaunchUrl(smsUri)) {
            launched = await launchUrl(smsUri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}

        if (!launched) {
          try {
            launched = await launchUrl(smsUri, mode: LaunchMode.externalApplication);
          } catch (_) {}
        }

        if (!launched) {
          await Share.share(message, subject: "EMERGENCY SOS ALERT - HealthShield AI");
        }
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error preparing SOS: $e"), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget targetScreen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textGrey,
            ),
          ],
        ),
      ),
    );
  }
}
