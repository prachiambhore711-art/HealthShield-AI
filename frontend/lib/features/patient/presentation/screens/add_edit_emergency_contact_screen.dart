import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import 'package:frontend/features/auth/presentation/widgets/custom_button.dart';
import 'package:frontend/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:frontend/features/patient/data/patient_service.dart';

class AddEditEmergencyContactScreen extends StatefulWidget {
  final Map<String, dynamic>? contact;

  const AddEditEmergencyContactScreen({
    Key? key,
    this.contact,
  }) : super(key: key);

  @override
  State<AddEditEmergencyContactScreen> createState() => _AddEditEmergencyContactScreenState();
}

class _AddEditEmergencyContactScreenState extends State<AddEditEmergencyContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();

  late TextEditingController _nameController;
  late TextEditingController _relationshipController;
  late TextEditingController _phoneController;
  bool _isPrimary = false;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?["name"] ?? "");
    _relationshipController = TextEditingController(text: widget.contact?["relationship"] ?? "");
    _phoneController = TextEditingController(text: widget.contact?["phone_number"] ?? "");
    _isPrimary = widget.contact?["is_primary"] == true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final relationship = _relationshipController.text.trim();
    final phone = _phoneController.text.trim();

    Map<String, dynamic> result;

    if (widget.contact != null) {
      // Edit mode
      result = await _patientService.updateEmergencyContact(
        id: widget.contact!["id"],
        name: name,
        relationship: relationship,
        phoneNumber: phone,
        isPrimary: _isPrimary,
      );
    } else {
      // Add mode
      result = await _patientService.addEmergencyContact(
        name: name,
        relationship: relationship,
        phoneNumber: phone,
        isPrimary: _isPrimary,
      );
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.contact != null
                ? "Contact updated successfully!"
                : "Contact added successfully!"),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
      } else {
        setState(() {
          _errorMessage = result["message"];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.contact != null;

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
          title: Text(
            isEditMode ? "Edit Contact" : "Add Contact",
            style: const TextStyle(
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
                  const SizedBox(height: 20),
                ],

                // 1. Full Name
                const Text(
                  "Full Name",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _nameController,
                  hintText: "e.g. Anita Sharma",
                  prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.textGrey, size: 20),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Contact name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. Relationship
                const Text(
                  "Relationship",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _relationshipController,
                  hintText: "e.g. Mother, Spouse, Friend",
                  prefixIcon: const Icon(Icons.family_restroom_rounded, color: AppColors.textGrey, size: 20),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Relationship is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Phone Number
                const Text(
                  "Phone Number",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _phoneController,
                  hintText: "e.g. +919876543210",
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.textGrey, size: 20),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Phone number is required";
                    }
                    final cleaned = val.replaceAll(RegExp(r'[\s\-()]'), '');
                    if (!RegExp(r'^\+?[0-9]{10,14}$').hasMatch(cleaned)) {
                      return "Enter valid phone number (10-14 digits, optional +)";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 4. Primary Contact Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGrey, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Primary Contact",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Call this contact first in emergencies",
                            style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isPrimary,
                        activeColor: AppColors.green,
                        onChanged: (val) {
                          setState(() {
                            _isPrimary = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Privacy / Emergency Transparency notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mint.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.deepGreen.withOpacity(0.2)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: AppColors.deepGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Emergency Transparency Notice: Your primary contact's phone number is visible to first responders scanning your emergency QR code so they can reach help immediately. Non-primary contacts remain private.",
                          style: TextStyle(fontSize: 11, color: AppColors.textDark, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 5. Action Buttons
                CustomButton(
                  text: isEditMode ? "Save Changes" : "Save Contact",
                  isLoading: _isSaving,
                  onPressed: _saveContact,
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
}
