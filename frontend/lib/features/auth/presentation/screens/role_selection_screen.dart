import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/server_config_dialog.dart';
import '../../../patient/presentation/screens/public_emergency_screen.dart';
import '../../../patient/presentation/screens/public_qr_scanner_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  void _openPublicEmergencyDialog(BuildContext context) {
    final TextEditingController tokenController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.emergency_rounded, color: AppColors.errorRed),
            SizedBox(width: 8),
            Text("Emergency QR Access", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PublicQrScannerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.white, size: 20),
                  label: const Text("Scan QR with Camera", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.borderGrey)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("OR ENTER TOKEN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
                  ),
                  Expanded(child: Divider(color: AppColors.borderGrey)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Enter token from patient's Emergency QR screen or card (e.g. HS-E:...):",
                style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tokenController,
                decoration: InputDecoration(
                  hintText: "HS-E:...",
                  filled: true,
                  fillColor: AppColors.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderGrey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              final token = tokenController.text.trim();
              if (token.isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicEmergencyScreen(token: token),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Lookup", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String description,
    required String imageAsset,
    required Color color,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderGrey.withOpacity(0.6), width: 1.2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              children: [
                // Illustration Avatar
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        imageAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          color: color,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.textDark,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                // Arrow Indicator with Gradient Accent
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.wifi_tethering_rounded, color: AppColors.textDark),
              tooltip: "Server Settings",
              onPressed: () => ServerConfigDialog.show(context),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                const SizedBox(height: 8),
                // Original Brand Logo Asset
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.shield_rounded,
                            size: 36,
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Heading
                Text(
                  "Choose How You Access\nHealthShield AI",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.textDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                ),
                const SizedBox(height: 8),
                // Subheading
                Text(
                  "Select your portal to securely manage or review medical records",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textGrey,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                ),
                const SizedBox(height: 24),
                // Patient Card
                _buildRoleCard(
                  context: context,
                  title: "Patient",
                  description: "Manage your health securely",
                  imageAsset: "assets/images/illustrations/role_patient.png",
                  color: AppColors.green,
                  iconBgColor: AppColors.veryLightMint,
                  onTap: () {
                    Navigator.pushNamed(context, '/patient-login');
                  },
                ),
                const SizedBox(height: 14),
                // Doctor Card
                _buildRoleCard(
                  context: context,
                  title: "Doctor",
                  description: "Access authorized emergency information",
                  imageAsset: "assets/images/illustrations/role_doctor.png",
                  color: AppColors.deepGreen,
                  iconBgColor: AppColors.softMint,
                  onTap: () {
                    Navigator.pushNamed(context, '/doctor-login');
                  },
                ),
                const SizedBox(height: 14),
                // Admin Card
                _buildRoleCard(
                  context: context,
                  title: "Admin",
                  description: "System administration & doctor verification",
                  imageAsset: "assets/images/illustrations/login_admin.png",
                  color: const Color(0xFF3949AB),
                  iconBgColor: const Color(0xFFE8EAF6),
                  onTap: () {
                    Navigator.pushNamed(context, '/admin-login');
                  },
                ),
                const SizedBox(height: 22),
                // Emergency Access Section Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.borderGrey.withOpacity(0.8), thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.emergency_rounded, size: 14, color: AppColors.errorRed),
                          SizedBox(width: 4),
                          Text(
                            "EMERGENCY ACCESS",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: AppColors.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.borderGrey.withOpacity(0.8), thickness: 1)),
                  ],
                ),
                const SizedBox(height: 14),
                // Public Emergency Access (Bystander / First-responder)
                InkWell(
                  onTap: () => _openPublicEmergencyDialog(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.softEmergencyBg,
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
                          child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Scan / Lookup Emergency QR",
                                style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "First-responder & bystander QR access (No login required)",
                                style: TextStyle(color: AppColors.textGrey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.errorRed, size: 14),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Footer note
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "You can change role later",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  },
),
),
),
);
  }
}
