import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart';
import 'package:frontend/features/patient/data/patient_service.dart';
import '../../../../core/services/app_lock_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _patientService = PatientService();
  bool _isRegenerating = false;
  bool _isLockEnabled = false;
  bool _isBiometricsEnabled = false;
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadLockSettings();
  }

  Future<void> _loadLockSettings() async {
    final lockOn = await AppLockService.isLockEnabled();
    final bioOn = await AppLockService.isBiometricsEnabled();
    final canBio = await AppLockService.canCheckBiometrics();
    if (mounted) {
      setState(() {
        _isLockEnabled = lockOn;
        _isBiometricsEnabled = bioOn;
        _canCheckBiometrics = canBio;
      });
    }
  }

  Future<void> _promptSetPin() async {
    final TextEditingController pinCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Set 4-Digit App PIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose a 4-digit PIN to protect private medical records when reopening the app:",
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: AppColors.lightSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinCtrl.text.trim().length == 4) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            child: const Text("Save PIN", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && pinCtrl.text.trim().length == 4) {
      await AppLockService.setPin(pinCtrl.text.trim());
      await _loadLockSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("App PIN successfully configured!"), backgroundColor: AppColors.green),
        );
      }
    }
  }

  Future<void> _toggleBiometrics(bool val) async {
    if (!_isLockEnabled && val) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable App PIN first before enabling Biometrics.")),
      );
      return;
    }
    await AppLockService.setBiometricsEnabled(val);
    await _loadLockSettings();
  }

  Future<void> _toggleLock(bool val) async {
    if (val) {
      await _promptSetPin();
    } else {
      await AppLockService.disableLock();
      await _loadLockSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("App Lock disabled."), backgroundColor: AppColors.textDark),
        );
      }
    }
  }

  Future<void> _confirmRegenerateQr() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Regenerate QR Token",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Regenerating your Emergency QR will immediately invalidate your current QR code.\n\n"
          "If anyone scans your old QR code, they will be blocked and cannot access your emergency information. "
          "Do you want to proceed?",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Regenerate",
              style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isRegenerating = true;
      });

      final result = await _patientService.regenerateEmergencyQr();

      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });

        if (result["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Emergency QR successfully regenerated! The old QR is now invalid."),
              backgroundColor: AppColors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result["message"]),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
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
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Settings",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // 1. Emergency Settings section
            const Text(
              "Emergency Configuration",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Emergency QR Token",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Regenerate your emergency identifier token if your print card is lost or the QR was scanned by unauthorized persons.",
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _isRegenerating ? null : _confirmRegenerateQr,
                      icon: _isRegenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 18, color: AppColors.white),
                      label: const Text("Cycle QR Security Key", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. Privacy & App Lock section
            const Text(
              "Privacy & Security Lock",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Require App PIN",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    subtitle: const Text(
                      "Require 4-digit PIN when opening app or returning from background.",
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
                    ),
                    value: _isLockEnabled,
                    activeColor: AppColors.green,
                    onChanged: (val) => _toggleLock(val),
                  ),
                  if (_isLockEnabled) ...[
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Change PIN",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        TextButton.icon(
                          onPressed: _promptSetPin,
                          icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.green),
                          label: const Text("Update PIN", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                    if (_canCheckBiometrics) ...[
                      const Divider(height: 20),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          "Biometric Unlock",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        subtitle: const Text(
                          "Use Fingerprint or Face unlock in addition to PIN.",
                          style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.3),
                        ),
                        value: _isBiometricsEnabled,
                        activeColor: AppColors.green,
                        onChanged: (val) => _toggleBiometrics(val),
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textGrey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Public emergency QR scanning and first-responder lookup remain accessible without PIN unlock.",
                            style: TextStyle(fontSize: 11, color: AppColors.textGrey, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 3. About Section
            const Text(
              "About",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text("Application Name", style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                      ),
                      const SizedBox(width: 8),
                      const Text("HealthShield AI", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.borderGrey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text("Tagline", style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                      ),
                      const SizedBox(width: 8),
                      const Text("Your Health, Your Shield", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textDark)),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.borderGrey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text("Version", style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                      ),
                      const SizedBox(width: 8),
                      const Text("1.0.0 (Release Build)", style: TextStyle(fontSize: 13, color: AppColors.textDark)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
