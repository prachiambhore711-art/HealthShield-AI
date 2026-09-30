import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/admin_service.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final _adminService = AdminService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    if (AuthService.userRole != "admin") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/role-selection');
      });
    } else {
      _loadLogs();
    }
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
    });

    final results = await _adminService.getAuditLogs();

    if (mounted) {
      setState(() {
        _logs = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Administrative Logs",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.deepGreen),
            )
          : _logs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  color: AppColors.deepGreen,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _logs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _buildAuditLogTile(log);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.textGrey, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              "No Audit History",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "No verification status adjustments or administrative updates have been logged yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogTile(Map<String, dynamic> log) {
    final adminName = log["admin_name"] ?? "Admin";
    final targetName = log["target_user_name"] ?? "User";
    final action = log["action"] ?? "";
    final prev = log["previous_status"] ?? "";
    final next = log["new_status"] ?? "";
    final notes = log["notes"] ?? "";
    final rawDate = log["created_at"] ?? "";
    
    // Parse date snippet
    String dateStr = "";
    try {
      final parsed = DateTime.parse(rawDate);
      dateStr = "${parsed.day}/${parsed.month}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      dateStr = rawDate.toString();
    }

    Color actionColor = AppColors.deepGreen;
    if (action == "verify" || action == "reactivate") actionColor = AppColors.successGreen;
    if (action == "reject" || action == "suspend") actionColor = AppColors.errorRed;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGrey, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    action.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: actionColor,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.3),
                children: [
                  TextSpan(text: adminName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: " updated verification status for "),
                  TextSpan(text: targetName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (prev.isNotEmpty && next.isNotEmpty) ...[
                    const TextSpan(text: " from "),
                    TextSpan(text: prev, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                    const TextSpan(text: " to "),
                    TextSpan(text: next, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ],
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Notes: $notes",
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
