import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import 'package:frontend/features/auth/presentation/widgets/custom_button.dart';
import 'package:frontend/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:frontend/features/patient/data/patient_service.dart';

class EditMedicalProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditMedicalProfileScreen({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<EditMedicalProfileScreen> createState() => _EditMedicalProfileScreenState();
}

class _EditMedicalProfileScreenState extends State<EditMedicalProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();

  String? _selectedBloodGroup;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _medicationsController;
  late TextEditingController _notesController;

  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

  @override
  void initState() {
    super.initState();
    final bg = widget.profile["blood_group"]?.toString().toUpperCase() ?? "";
    _selectedBloodGroup = _bloodGroups.contains(bg) ? bg : null;

    _heightController = TextEditingController(text: widget.profile["height"]?.toString() ?? "");
    _weightController = TextEditingController(text: widget.profile["weight"]?.toString() ?? "");
    _allergiesController = TextEditingController(text: widget.profile["allergies"]?.toString() ?? "");
    _conditionsController = TextEditingController(text: widget.profile["conditions"]?.toString() ?? "");
    _medicationsController = TextEditingController(text: widget.profile["medications"]?.toString() ?? "");
    _notesController = TextEditingController(text: widget.profile["critical_notes"]?.toString() ?? "");
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final payload = {
      "blood_group": _selectedBloodGroup ?? "",
      "height": _heightController.text.trim(),
      "weight": _weightController.text.trim(),
      "allergies": _allergiesController.text.trim(),
      "conditions": _conditionsController.text.trim(),
      "medications": _medicationsController.text.trim(),
      "critical_notes": _notesController.text.trim(),
    };

    final result = await _patientService.updateMedicalProfile(payload);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result["success"]) {
        // Show success confirmation screen or snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Medical Profile updated successfully!"),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh profile list
      } else {
        setState(() {
          _errorMessage = result["message"];
        });
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
            "Edit Medical Profile",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                ],

                // 1. Blood Group Dropdown
                const Text(
                  "Blood Group",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedBloodGroup,
                  hint: const Text("Select Blood Group", style: TextStyle(color: AppColors.textGrey)),
                  decoration: InputDecoration(
                    fillColor: AppColors.inputBackground,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey, width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGrey, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                    ),
                  ),
                  dropdownColor: AppColors.white,
                  items: _bloodGroups.map((group) {
                    return DropdownMenuItem<String>(
                      value: group,
                      child: Text(group, style: const TextStyle(color: AppColors.textDark)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBloodGroup = val;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 2. Height and Weight Input
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Height (cm)",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _heightController,
                            hintText: "e.g. 175",
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.height_rounded, color: AppColors.textGrey, size: 20),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (double.tryParse(val) == null) {
                                  return "Must be numeric";
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Weight (kg)",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _weightController,
                            hintText: "e.g. 70",
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.monitor_weight_outlined, color: AppColors.textGrey, size: 20),
                            validator: (val) {
                              if (val != null && val.trim().isNotEmpty) {
                                if (double.tryParse(val) == null) {
                                  return "Must be numeric";
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Medical Conditions
                const Text(
                  "Medical Conditions",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                _buildTextArea(
                  controller: _conditionsController,
                  hintText: "List any chronic illnesses, major operations, or long-term medical conditions...",
                ),
                const SizedBox(height: 20),

                // 4. Allergies
                const Text(
                  "Allergies",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                _buildTextArea(
                  controller: _allergiesController,
                  hintText: "List drug allergies, food allergies, or any other severe hypersensitivity details...",
                ),
                const SizedBox(height: 20),

                // 5. Current Medications
                const Text(
                  "Current Medications",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                _buildTextArea(
                  controller: _medicationsController,
                  hintText: "List current prescriptions, dosages, schedules, and frequencies...",
                ),
                const SizedBox(height: 20),

                // 6. Critical Notes & Precautions
                const Text(
                  "Critical Notes & Precautions",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                _buildTextArea(
                  controller: _notesController,
                  hintText: "Add specific advice for paramedics, like 'Asthmatic, carries inhaler' or 'Diabetic'...",
                ),
                const SizedBox(height: 32),

                // 7. Save Changes Buttons
                CustomButton(
                  text: "Save Changes",
                  isLoading: _isSaving,
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderGrey, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        fillColor: AppColors.inputBackground,
        filled: true,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGrey, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderGrey, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }
}
