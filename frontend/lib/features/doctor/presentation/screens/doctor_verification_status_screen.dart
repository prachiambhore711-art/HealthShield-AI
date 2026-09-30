import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/doctor_service.dart';

class DoctorVerificationStatusScreen extends StatefulWidget {
  const DoctorVerificationStatusScreen({Key? key}) : super(key: key);

  @override
  State<DoctorVerificationStatusScreen> createState() => _DoctorVerificationStatusScreenState();
}

class _DoctorVerificationStatusScreenState extends State<DoctorVerificationStatusScreen> {
  final DoctorService _doctorService = DoctorService();
  bool _isLoading = true;
  String _status = "pending";
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _doctorService.getVerificationStatus();
    if (!mounted) return;

    if (res["success"]) {
      setState(() {
        _status = res["status"] ?? "pending";
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res["message"];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = AppColors.warningOrange;
    String statusTitle = "Verification Pending";
    String description = "Your doctor credentials have been registered and are currently in the queue for administrative validation. Emergency access and QR scanning are disabled until verification completes.";
    IconData icon = Icons.hourglass_empty_rounded;

    if (_status == "verified") {
      themeColor = AppColors.green;
      statusTitle = "Verified Professional";
      description = "Your account is verified. You have full emergency access to patient parameters and reports via secure QR scanning.";
      icon = Icons.verified_user_rounded;
    } else if (_status == "rejected") {
      themeColor = AppColors.errorRed;
      statusTitle = "Verification Rejected";
      description = "Your medical registration has been rejected by administrators. Please update your profile license information or contact support.";
      icon = Icons.gpp_bad_outlined;
    } else if (_status == "suspended") {
      themeColor = AppColors.errorRed;
      statusTitle = "Account Suspended";
      description = "Your doctor account is temporarily suspended. Access to patient files is restricted.";
      icon = Icons.block_flipped;
    }

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
          "Verification Status",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.deepGreen))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderGrey, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: themeColor, size: 54),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            statusTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _checkStatus,
                        icon: const Icon(Icons.sync_rounded, color: AppColors.white),
                        label: const Text(
                          "Refresh Verification Status",
                          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
