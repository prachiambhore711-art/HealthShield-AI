import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import 'package:frontend/features/patient/data/patient_service.dart';

class EmergencyAccessScreen extends StatefulWidget {
  final bool isNavigatedFromNavBar;

  const EmergencyAccessScreen({
    Key? key,
    this.isNavigatedFromNavBar = false,
  }) : super(key: key);

  @override
  State<EmergencyAccessScreen> createState() => _EmergencyAccessScreenState();
}

class _EmergencyAccessScreenState extends State<EmergencyAccessScreen> with SingleTickerProviderStateMixin {
  final _patientService = PatientService();
  late TabController _tabController;

  bool _isLoading = true;
  List<Map<String, dynamic>> _activeAccesses = [];
  List<Map<String, dynamic>> _accessHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAccessData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAccessData() async {
    setState(() {
      _isLoading = true;
    });

    final activeList = await _patientService.getActiveEmergencyAccess();
    final historyList = await _patientService.getEmergencyAccessHistory();

    if (mounted) {
      setState(() {
        _activeAccesses = activeList;
        _accessHistory = historyList;
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeAccess(int accessId, String doctorName) async {
    final cleanDocName = doctorName.replaceFirst(RegExp(r'^(dr\.?|doctor)\s+', caseSensitive: false), '').trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Revoke Access", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to immediately revoke emergency records access for Dr. $cleanDocName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Revoke Now", style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      final result = await _patientService.revokeEmergencyAccess(accessId);

      if (mounted) {
        if (result["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Access revoked for Dr. $doctorName."),
              backgroundColor: AppColors.green,
            ),
          );
          _loadAccessData();
        } else {
          setState(() {
            _isLoading = false;
          });
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

  String _formatDateTime(String dateTimeStr) {
    try {
      final parsed = DateTime.parse(dateTimeStr).toLocal();
      final month = parsed.month.toString().padLeft(2, '0');
      final day = parsed.day.toString().padLeft(2, '0');
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return "${parsed.year}-$month-$day $hour:$minute";
    } catch (e) {
      return dateTimeStr;
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
          leading: widget.isNavigatedFromNavBar
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context),
                ),
          title: const Text(
            "Share QR / Permissions",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.green,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.green,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: "Active Access"),
              Tab(text: "Access History"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.green))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveAccessList(),
                  _buildAccessHistoryList(),
                ],
              ),
      ),
    );
  }

  Widget _buildActiveAccessList() {
    if (_activeAccesses.isEmpty) {
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
                  Icons.vpn_key_outlined,
                  color: AppColors.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "No active access permissions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                "When a doctor scans your emergency QR code, their active access session will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: _activeAccesses.length,
      itemBuilder: (context, index) {
        final access = _activeAccesses[index];
        final rawDocName = access["doctor_name"] ?? "Doctor";
        final cleanDocName = rawDocName.replaceFirst(RegExp(r'^(dr\.?|doctor)\s+', caseSensitive: false), '').trim();
        final doctorName = cleanDocName.isNotEmpty ? cleanDocName : rawDocName;
        final doctorEmail = access["doctor_email"] ?? "";
        final expiresAt = _formatDateTime(access["expires_at"]);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services_rounded, color: AppColors.deepGreen, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dr. $doctorName",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctorEmail,
                        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Expires: $expiresAt",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.warningOrange),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _revokeAccess(access["id"], doctorName),
                  child: const Text(
                    "Revoke",
                    style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccessHistoryList() {
    if (_accessHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            "No access history logs recorded.",
            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: _accessHistory.length,
      itemBuilder: (context, index) {
        final log = _accessHistory[index];
        final rawDocName = log["doctor_name"] ?? "Doctor";
        final cleanDocName = rawDocName.replaceFirst(RegExp(r'^(dr\.?|doctor)\s+', caseSensitive: false), '').trim();
        final doctorName = cleanDocName.isNotEmpty ? cleanDocName : rawDocName;
        final grantedAt = _formatDateTime(log["granted_at"]);
        final status = log["status"]?.toString().toUpperCase() ?? "EXPIRED";

        Color statusColor;
        switch (status) {
          case "ACTIVE":
            statusColor = AppColors.green;
            break;
          case "REVOKED":
            statusColor = AppColors.errorRed;
            break;
          default:
            statusColor = AppColors.textGrey;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGrey, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, color: AppColors.textGrey, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dr. $doctorName",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          grantedAt,
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
