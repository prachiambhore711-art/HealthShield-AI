import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import 'package:frontend/features/auth/presentation/widgets/custom_button.dart';
import 'package:frontend/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:frontend/features/patient/data/patient_service.dart';

class AddMedicalReportScreen extends StatefulWidget {
  const AddMedicalReportScreen({Key? key}) : super(key: key);

  @override
  State<AddMedicalReportScreen> createState() => _AddMedicalReportScreenState();
}

class _AddMedicalReportScreenState extends State<AddMedicalReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();

  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedType;
  String? _selectedFilePath;
  String? _selectedFileName;
  int? _selectedFileSize;

  bool _isUploading = false;
  String? _errorMessage;

  final List<String> _reportTypes = ["Blood Test", "Prescription", "X-Ray / Scan", "Vaccination", "Other"];

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _selectedFileName = result.files.single.name;
          _selectedFileSize = result.files.single.size;
          _errorMessage = null; // Clear previous error
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error selecting file: $e";
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.green,
              onPrimary: AppColors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final year = picked.year;
        final month = picked.month.toString().padLeft(2, '0');
        final day = picked.day.toString().padLeft(2, '0');
        _dateController.text = "$year-$month-$day";
      });
    }
  }

  Future<void> _uploadReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFilePath == null) {
      setState(() {
        _errorMessage = "Please select a medical document to upload.";
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    final result = await _patientService.uploadMedicalReport(
      title: _titleController.text.trim(),
      type: _selectedType ?? "Other",
      date: _dateController.text.trim(),
      description: _descriptionController.text.trim(),
      filePath: _selectedFilePath!,
    );

    if (mounted) {
      setState(() {
        _isUploading = false;
      });

      if (result["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Medical Report uploaded successfully!"),
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    final kb = bytes / 1024;
    if (kb < 1024) return "${kb.toStringAsFixed(1)} KB";
    final mb = kb / 1024;
    return "${mb.toStringAsFixed(1)} MB";
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
            "Add Medical Report",
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
                  const SizedBox(height: 20),
                ],

                // 1. Report Title
                const Text(
                  "Report Title",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _titleController,
                  hintText: "e.g. Lab Blood Work Results",
                  prefixIcon: const Icon(Icons.title_rounded, color: AppColors.textGrey, size: 20),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Title is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. Report Type Dropdown
                const Text(
                  "Report Type",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  hint: const Text("Select Report Type", style: TextStyle(color: AppColors.textGrey)),
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
                  items: _reportTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type, style: const TextStyle(color: AppColors.textDark)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedType = val;
                    });
                  },
                  validator: (val) {
                    if (val == null) {
                      return "Report type is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Date Picker Field
                const Text(
                  "Report Date",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "YYYY-MM-DD",
                    hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                    fillColor: AppColors.inputBackground,
                    filled: true,
                    prefixIcon: const Icon(Icons.calendar_month_rounded, color: AppColors.textGrey, size: 20),
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
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Report date is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 4. File Selector Card
                const Text(
                  "Attached File",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedFilePath != null ? AppColors.green : AppColors.borderGrey,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _selectedFilePath != null
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedFileName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatBytes(_selectedFileSize!),
                                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _pickFile,
                                child: const Text("Change", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_outlined, color: AppColors.textGrey, size: 28),
                              const SizedBox(width: 12),
                              Text(
                                "Choose File (PDF, JPG, PNG)",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.green.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Description Note
                const Text(
                  "Description / Notes (Optional)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Add any extra context, doctor notes, or findings...",
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
                ),
                const SizedBox(height: 36),

                // 6. Submit Actions
                CustomButton(
                  text: "Upload Report",
                  isLoading: _isUploading,
                  onPressed: _uploadReport,
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
