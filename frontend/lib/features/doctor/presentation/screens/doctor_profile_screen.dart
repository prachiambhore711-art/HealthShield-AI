import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../data/doctor_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorService _doctorService = DoctorService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  Map<String, dynamic>? _profile;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _doctorService.getDoctorProfile();
    if (!mounted) return;

    if (res["success"]) {
      setState(() {
        _profile = res["profile"];
        _nameController.text = _profile?["full_name"] ?? "";
        _emailController.text = _profile?["email"] ?? "";
        _phoneController.text = _profile?["phone_number"] ?? "";
        _licenseController.text = _profile?["professional_id"] ?? "";
        _specializationController.text = _profile?["specialization"] ?? "";
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res["message"];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final res = await _doctorService.updateDoctorProfile(
      professionalId: _licenseController.text.trim(),
      specialization: _specializationController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (res["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: AppColors.successGreen,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = res["message"];
      });
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
          "My Profile",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.errorRed, width: 0.8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Verification Banner Card
                    _buildVerificationBanner(),
                    const SizedBox(height: 28),

                    // Immutable Account Fields Section
                    const Text(
                      "Account Settings (Read-Only)",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      hintText: "",
                      controller: _nameController,
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: "",
                      controller: _emailController,
                      labelText: "Email Address",
                      prefixIcon: const Icon(Icons.email_outlined),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: "",
                      controller: _phoneController,
                      labelText: "Phone Number",
                      prefixIcon: const Icon(Icons.phone_outlined),
                      readOnly: true,
                    ),
                    const SizedBox(height: 28),

                    // Editable Professional Details Section
                    const Text(
                      "Professional Credentials",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _specializationController,
                      labelText: "Medical Specialization",
                      hintText: "e.g. Emergency Medicine, Cardiologist",
                      prefixIcon: const Icon(Icons.stars_outlined),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Specialization is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _licenseController,
                      labelText: "Medical License / ID Number",
                      hintText: "Enter government registration ID",
                      prefixIcon: const Icon(Icons.badge_outlined),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "License ID is required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    CustomButton(
                      text: "Save Professional Info",
                      gradient: AppColors.doctorGradient,
                      isLoading: _isSaving,
                      onPressed: _saveProfile,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVerificationBanner() {
    final status = _profile?["doctor_verification_status"] ?? "pending";
    Color bannerColor = AppColors.warningOrange;
    String text = "Administrative Verification Pending";
    IconData icon = Icons.hourglass_top_rounded;

    if (status == "verified") {
      bannerColor = AppColors.green;
      text = "Verified Medical Professional";
      icon = Icons.verified_user_rounded;
    } else if (status == "rejected") {
      bannerColor = AppColors.errorRed;
      text = "Professional Verification Rejected";
      icon = Icons.gpp_bad_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withOpacity(0.3), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: bannerColor == AppColors.green ? bannerColor : AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
