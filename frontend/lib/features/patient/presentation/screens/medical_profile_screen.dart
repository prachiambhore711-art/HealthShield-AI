import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import 'package:frontend/features/patient/data/patient_service.dart';
import 'edit_medical_profile_screen.dart';

class MedicalProfileScreen extends StatefulWidget {
  final bool isNavigatedFromNavBar;

  const MedicalProfileScreen({
    Key? key,
    this.isNavigatedFromNavBar = false,
  }) : super(key: key);

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  final _patientService = PatientService();
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profile;

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

    final result = await _patientService.getMedicalProfile();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result["success"]) {
          _profile = result["profile"];
        } else {
          _errorMessage = result["message"];
        }
      });
    }
  }

  String _calculateBmi() {
    if (_profile == null) return "N/A";
    final heightStr = _profile!["height"]?.toString() ?? "";
    final weightStr = _profile!["weight"]?.toString() ?? "";

    // Parse height and weight by stripping non-numeric chars
    final cleanHeight = heightStr.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanWeight = weightStr.replaceAll(RegExp(r'[^0-9.]'), '');

    final double? heightCm = double.tryParse(cleanHeight);
    final double? weightKg = double.tryParse(cleanWeight);

    if (heightCm != null && weightKg != null && heightCm > 0) {
      final double heightM = heightCm / 100.0;
      final double bmi = weightKg / (heightM * heightM);
      return bmi.toStringAsFixed(1);
    }
    return "N/A";
  }

  bool _isProfileEmpty() {
    if (_profile == null) return true;
    return (_profile!["blood_group"]?.isEmpty ?? true) &&
        (_profile!["height"]?.isEmpty ?? true) &&
        (_profile!["weight"]?.isEmpty ?? true) &&
        (_profile!["allergies"]?.isEmpty ?? true) &&
        (_profile!["conditions"]?.isEmpty ?? true) &&
        (_profile!["medications"]?.isEmpty ?? true) &&
        (_profile!["critical_notes"]?.isEmpty ?? true);
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.isNavigatedFromNavBar
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
          title: const Text(
            "Medical Profile",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            if (!_isLoading && _profile != null)
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.green),
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditMedicalProfileScreen(profile: _profile!),
                    ),
                  );
                  if (updated == true) {
                    _loadProfile();
                  }
                },
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.green),
            SizedBox(height: 16),
            Text(
              "Loading your medical profile...",
              style: TextStyle(color: AppColors.textGrey, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh, color: AppColors.white),
                label: const Text("Retry", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                  iconColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isProfileEmpty()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_ind_outlined,
                  color: AppColors.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Your medical profile is incomplete",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please fill in your basic medical identity details so doctors can access them in an emergency.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditMedicalProfileScreen(profile: _profile ?? {}),
                    ),
                  );
                  if (updated == true) {
                    _loadProfile();
                  }
                },
                icon: const Icon(Icons.add_rounded, color: AppColors.white),
                label: const Text(
                  "Complete Medical Profile",
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                  iconColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Dynamic Calculated BMI
    final String bmiVal = _calculateBmi();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Health Records Stats Row
          Row(
            children: [
              Expanded(
                child: _buildHealthParamCard(
                  title: "Blood Group",
                  value: _profile!["blood_group"]?.toString().toUpperCase() ?? "N/A",
                  icon: Icons.bloodtype_rounded,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHealthParamCard(
                  title: "Height",
                  value: _profile!["height"]?.toString() ?? "N/A",
                  icon: Icons.height_rounded,
                  color: AppColors.deepGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHealthParamCard(
                  title: "Weight",
                  value: _profile!["weight"]?.toString() ?? "N/A",
                  icon: Icons.monitor_weight_outlined,
                  color: AppColors.deepGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHealthParamCard(
                  title: "BMI Score",
                  value: bmiVal,
                  icon: Icons.speed_rounded,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // 2. Detailed Medical Information
          const Text(
            "My Medical Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          _buildMedicalInfoTile(
            title: "Medical Conditions",
            content: _profile!["conditions"],
            icon: Icons.favorite_border_rounded,
            color: AppColors.errorRed,
            placeholder: "No chronic conditions or diseases listed.",
          ),
          const SizedBox(height: 16),

          _buildMedicalInfoTile(
            title: "Allergies",
            content: _profile!["allergies"],
            icon: Icons.warning_amber_rounded,
            color: AppColors.warningOrange,
            placeholder: "No documented drug, food, or other allergies.",
          ),
          const SizedBox(height: 16),

          _buildMedicalInfoTile(
            title: "Current Medications",
            content: _profile!["medications"],
            icon: Icons.medication_outlined,
            color: AppColors.green,
            placeholder: "No active regular medications listed.",
          ),
          const SizedBox(height: 16),

          _buildMedicalInfoTile(
            title: "Critical Notes & Precautions",
            content: _profile!["critical_notes"],
            icon: Icons.notes_rounded,
            color: AppColors.deepGreen,
            placeholder: "No additional emergency precautions added.",
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHealthParamCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value.isEmpty ? "N/A" : value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoTile({
    required String title,
    required String? content,
    required IconData icon,
    required Color color,
    required String placeholder,
  }) {
    final bool hasContent = content != null && content.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderGrey),
          Text(
            hasContent ? content! : placeholder,
            style: TextStyle(
              fontSize: 13,
              color: hasContent ? AppColors.textDark : AppColors.textGrey,
              fontStyle: hasContent ? FontStyle.normal : FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
