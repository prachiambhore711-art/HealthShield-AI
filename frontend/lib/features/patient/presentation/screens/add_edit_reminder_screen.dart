import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../data/reminder_service.dart';

class AddEditReminderScreen extends StatefulWidget {
  final Map<String, dynamic>? reminder;

  const AddEditReminderScreen({Key? key, this.reminder}) : super(key: key);

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReminderService _reminderService = ReminderService();

  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;

  String _selectedFrequency = "Once daily";
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _frequencies = [
    "Once daily",
    "Twice daily",
    "Thrice daily",
    "Every 8 hours",
    "Every 12 hours",
    "Before meals",
    "After meals",
    "As needed",
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _nameController = TextEditingController(text: r?['medication_name'] ?? '');
    _dosageController = TextEditingController(text: r?['dosage'] ?? '');
    _notesController = TextEditingController(text: r?['notes'] ?? '');

    if (r != null) {
      if (_frequencies.contains(r['frequency'])) {
        _selectedFrequency = r['frequency'];
      }
      final timeStr = r['reminder_times'] ?? '08:00';
      final parts = timeStr.toString().split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 8;
        final m = int.tryParse(parts[1].split(' ')[0]) ?? 0;
        _selectedTime = TimeOfDay(hour: h, minute: m);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final payload = {
      "medication_name": _nameController.text.trim(),
      "dosage": _dosageController.text.trim(),
      "frequency": _selectedFrequency,
      "reminder_times": _formatTimeOfDay(_selectedTime),
      "notes": _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      "is_active": widget.reminder?['is_active'] ?? true,
    };

    final isEdit = widget.reminder != null;
    final Map<String, dynamic> res;

    if (isEdit) {
      res = await _reminderService.updateReminder(widget.reminder!['id'], payload);
    } else {
      res = await _reminderService.createReminder(payload);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      final savedItem = res['data'] ?? payload;
      final int savedId = savedItem['id'] ?? widget.reminder?['id'] ?? 1;

      // Schedule notification
      await NotificationService.scheduleMedicationAlert(
        savedId,
        _nameController.text.trim(),
        _dosageController.text.trim(),
        _formatTimeOfDay(_selectedTime),
        frequency: _selectedFrequency,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? "Reminder updated" : "Medication reminder created"),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = res['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reminder != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? "Edit Reminder" : "New Reminder",
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.softEmergencyBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: AppColors.errorRed, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text("Medication Name", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _nameController,
                hintText: "e.g., Amoxicillin, Metformin, Vitamin D",
                prefixIcon: const Icon(Icons.medication_rounded, color: AppColors.textGrey, size: 20),
                validator: (val) => val == null || val.trim().isEmpty ? "Medication name is required" : null,
              ),
              const SizedBox(height: 20),
              const Text("Dosage", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _dosageController,
                hintText: "e.g., 500 mg, 1 tablet, 10 ml",
                prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.textGrey, size: 20),
                validator: (val) => val == null || val.trim().isEmpty ? "Dosage is required" : null,
              ),
              const SizedBox(height: 20),
              const Text("Frequency", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGrey, width: 1.2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFrequency,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textGrey),
                    items: _frequencies.map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(color: AppColors.textDark, fontSize: 14)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedFrequency = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Reminder Time", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGrey, width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: AppColors.green, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime.format(context),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ],
                      ),
                      const Text("Change", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Instructions / Notes (Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14)),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _notesController,
                hintText: "e.g., Take with a full glass of water after breakfast",
                prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textGrey, size: 20),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: isEdit ? "Update Reminder" : "Create Reminder",
                isLoading: _isLoading,
                onPressed: _saveReminder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
