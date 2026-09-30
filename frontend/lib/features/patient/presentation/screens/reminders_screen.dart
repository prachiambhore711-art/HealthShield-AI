import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/reminder_service.dart';
import 'add_edit_reminder_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _reminderService = ReminderService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final data = await _reminderService.getReminders();
    if (mounted) {
      setState(() {
        _reminders = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleReminder(Map<String, dynamic> reminder) async {
    final int id = reminder['id'];
    final bool currentActive = reminder['is_active'] ?? true;
    final res = await _reminderService.toggleReminder(id);
    if (res['success']) {
      if (currentActive) {
        // Was active, now disabled
        await NotificationService.cancelMedicationAlert(id);
      } else {
        // Was disabled, now enabled
        await NotificationService.scheduleMedicationAlert(
          id,
          reminder['medication_name'] ?? 'Medication',
          reminder['dosage'] ?? '',
          reminder['reminder_times'] ?? '',
          frequency: reminder['frequency'] ?? 'Once daily',
        );
      }
      _loadReminders();
    }
  }

  Future<void> _deleteReminder(int id, String medName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Reminder", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text("Are you sure you want to delete the reminder for $medName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.cancelMedicationAlert(id);
      final res = await _reminderService.deleteReminder(id);
      if (mounted) {
        if (res['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$medName reminder deleted"), backgroundColor: AppColors.green),
          );
          _loadReminders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message']), backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Medication Reminders",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditReminderScreen()),
          );
          if (result == true) {
            _loadReminders();
          }
        },
        backgroundColor: AppColors.green,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text("Add Reminder", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : _reminders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReminders,
                  color: AppColors.green,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: _reminders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _reminders[index];
                      return _buildReminderCard(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_rounded, size: 48, color: AppColors.deepGreen),
            ),
            const SizedBox(height: 20),
            const Text(
              "No Medication Reminders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              "Keep track of daily medications and pill schedules with automated notifications.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final bool isActive = reminder['is_active'] ?? true;
    final String medName = reminder['medication_name'] ?? 'Medication';
    final String dosage = reminder['dosage'] ?? '';
    final String freq = reminder['frequency'] ?? '';
    final String times = reminder['reminder_times'] ?? '';
    final String? notes = reminder['notes'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.green.withOpacity(0.3) : AppColors.borderGrey,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.mint : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_liquid_rounded,
                    color: isActive ? AppColors.deepGreen : AppColors.textGrey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppColors.textDark : AppColors.textGrey,
                          decoration: isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.veryLightMint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dosage,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.deepGreen),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            freq,
                            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeColor: AppColors.green,
                  onChanged: (_) => _toggleReminder(reminder),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.borderGrey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      times,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.textGrey),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddEditReminderScreen(reminder: reminder)),
                        );
                        if (result == true) {
                          _loadReminders();
                        }
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.errorRed),
                      onPressed: () => _deleteReminder(reminder['id'], medName),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "Note: $notes",
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
