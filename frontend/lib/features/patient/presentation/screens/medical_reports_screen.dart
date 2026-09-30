import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import 'package:frontend/features/patient/data/patient_service.dart';
import 'add_medical_report_screen.dart';
import 'report_viewer_screen.dart';
import 'package:http/http.dart' as http;
import '../../../../features/auth/data/auth_service.dart';

class MedicalReportsScreen extends StatefulWidget {
  const MedicalReportsScreen({Key? key}) : super(key: key);

  @override
  State<MedicalReportsScreen> createState() => _MedicalReportsScreenState();
}

class _MedicalReportsScreenState extends State<MedicalReportsScreen> {
  final _patientService = PatientService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });
    final list = await _patientService.getMedicalReports();
    if (mounted) {
      setState(() {
        _reports = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadReport(int id, String fileName) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Downloading $fileName...")),
    );

    try {
      final response = await http.get(
        Uri.parse("${AuthService.baseUrl}/api/patient/reports/$id/file"),
        headers: {
          if (AuthService.token != null) "Authorization": "Bearer ${AuthService.token}",
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Successfully downloaded $fileName (${response.bodyBytes.length} bytes)"),
              backgroundColor: AppColors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to download file: Status ${response.statusCode}"),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download error: $e"),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(int id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Report", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '$title'? This action cannot be undone."),
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
      final result = await _patientService.deleteMedicalReport(id);
      if (mounted) {
        if (result["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Report deleted successfully."), backgroundColor: AppColors.green),
          );
          _loadReports();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result["message"]), backgroundColor: AppColors.errorRed),
          );
        }
      }
    }
  }

  Future<void> _viewReport(Map<String, dynamic> report) async {
    final baseUrl = await AuthService.getBaseUrl();
    final fileUrl = '$baseUrl/api/patient/reports/${report["id"]}/file';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportViewerScreen(
          title: report["title"] ?? "Medical Report",
          fileUrl: fileUrl,
          fileName: report["file_name"] ?? "report.pdf",
        ),
      ),
    );
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
            "Medical Reports",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddMedicalReportScreen()),
            );
            if (added == true) {
              _loadReports();
            }
          },
          backgroundColor: AppColors.green,
          child: const Icon(Icons.add_rounded, color: AppColors.white),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.veryLightMint,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/images/illustrations/empty_reports.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.folder_open_rounded,
                        color: AppColors.green,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "No medical reports added yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                "Keep your medical files handy in case of emergencies.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final added = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddMedicalReportScreen()),
                  );
                  if (added == true) {
                    _loadReports();
                  }
                },
                icon: const Icon(Icons.add_rounded, color: AppColors.white),
                label: const Text(
                  "Add Medical Report",
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

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: AppColors.deepGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report["title"] ?? "Report",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.borderGrey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              report["type"]?.toString().toUpperCase() ?? "OTHER",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            report["report_date"] ?? "",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                      if (report["description"] != null && report["description"].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          report["description"],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_rounded, color: AppColors.green, size: 22),
                      tooltip: "View in-app",
                      onPressed: () => _viewReport(report),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppColors.deepGreen, size: 20),
                      tooltip: "Download file",
                      onPressed: () => _downloadReport(report["id"], report["file_name"]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                      tooltip: "Delete",
                      onPressed: () => _confirmDelete(report["id"], report["title"]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
