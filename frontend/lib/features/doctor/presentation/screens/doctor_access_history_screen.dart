import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/doctor_service.dart';

class DoctorAccessHistoryScreen extends StatefulWidget {
  const DoctorAccessHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DoctorAccessHistoryScreen> createState() => _DoctorAccessHistoryScreenState();
}

class _DoctorAccessHistoryScreenState extends State<DoctorAccessHistoryScreen> {
  final DoctorService _doctorService = DoctorService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    final list = await _doctorService.getAccessHistory();
    if (!mounted) return;
    setState(() {
      _history = list;
      _isLoading = false;
    });
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
          "Access History Logs",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepGreen))
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: AppColors.deepGreen,
              child: _history.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.history_toggle_off_rounded, color: AppColors.textGrey, size: 48),
                              SizedBox(height: 16),
                              Text(
                                "No access history recorded",
                                style: TextStyle(color: AppColors.textGrey, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24.0),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final patientName = item["patient_name"] ?? "Anonymous Patient";
                        final grantedAt = item["granted_at"] != null 
                            ? DateTime.parse(item["granted_at"]).toLocal().toString().substring(0, 16)
                            : "N/A";
                        final status = item["status"] ?? "unknown";

                        Color statusColor = AppColors.green;
                        IconData statusIcon = Icons.check_circle_outline_rounded;
                        String statusText = "Active";

                        if (status == "revoked") {
                          statusColor = AppColors.errorRed;
                          statusIcon = Icons.cancel_outlined;
                          statusText = "Revoked";
                        } else if (status == "expired") {
                          statusColor = AppColors.textGrey;
                          statusIcon = Icons.timer_off_outlined;
                          statusText = "Expired";
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderGrey, width: 1.2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Access Granted: $grantedAt",
                                      style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
