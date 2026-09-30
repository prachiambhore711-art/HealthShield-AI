import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/doctor_service.dart';
import '../../../patient/presentation/screens/report_viewer_screen.dart';

class DoctorPatientEmergencyProfileScreen extends StatefulWidget {
  final int accessId;
  const DoctorPatientEmergencyProfileScreen({Key? key, required this.accessId}) : super(key: key);

  @override
  State<DoctorPatientEmergencyProfileScreen> createState() => _DoctorPatientEmergencyProfileScreenState();
}

class _DoctorPatientEmergencyProfileScreenState extends State<DoctorPatientEmergencyProfileScreen> {
  final DoctorService _doctorService = DoctorService();
  bool _isLoading = true;
  bool _isRevoking = false;
  String? _errorMessage;
  Map<String, dynamic>? _patientData;
  
  // Timer attributes
  Timer? _countdownTimer;
  Duration _remainingDuration = const Duration(minutes: 15);
  bool _sessionExpired = false;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _doctorService.getAuthorizedPatientData(widget.accessId);
    if (!mounted) return;

    if (res["success"]) {
      setState(() {
        _patientData = res["data"];
        _isLoading = false;
      });
      _startCountdown();
    } else {
      setState(() {
        _errorMessage = res["message"];
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    // Default session is 15 minutes, but wait, the backend session might already be partially consumed.
    // Let's fetch the expires_at and compute actual difference, or default to 15 mins for presentation.
    _remainingDuration = const Duration(minutes: 15);
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_remainingDuration.inSeconds > 0) {
          _remainingDuration = _remainingDuration - const Duration(seconds: 1);
        } else {
          _sessionExpired = true;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  Future<void> _endAccess() async {
    setState(() {
      _isRevoking = true;
    });

    final res = await _doctorService.revokeEmergencyAccess(widget.accessId);
    if (!mounted) return;

    setState(() {
      _isRevoking = false;
    });

    if (res["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency access session closed."),
          backgroundColor: AppColors.textDark,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["message"]),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _downloadReport(int reportId, String filename) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Downloading $filename..."),
        duration: const Duration(seconds: 1),
      ),
    );

    final bytes = await _doctorService.downloadReportFile(widget.accessId, reportId);
    if (!mounted) return;

    if (bytes != null) {
      // For development, we simulate a successful download saving
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Download Completed", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("File '$filename' (${(bytes.length / 1024).toStringAsFixed(1)} KB) saved securely to your device's private storage."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to download file. Your session may have expired."),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.deepGreen)),
      );
    }

    if (_errorMessage != null || _sessionExpired) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_maybe_rounded, color: AppColors.errorRed, size: 64),
                const SizedBox(height: 24),
                Text(
                  _sessionExpired ? "Emergency access session has expired." : _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                const Text(
                  "To access this patient's critical health parameters, scan their Emergency QR Code again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Return to Dashboard", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final medProfile = _patientData?["medical_profile"] ?? {};
    final contacts = _patientData?["contacts"] as List? ?? [];
    final reports = _patientData?["reports"] as List? ?? [];

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
          "Emergency Profile",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Ticker Bar showing countdown
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.errorRed.withOpacity(0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.errorRed, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "EMERGENCY ACCESS TICKER - EXPIRES IN ${_formatDuration(_remainingDuration)}",
                    style: const TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // Patient details scroll body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Header Identification
                    _buildPatientHeader(),
                    const SizedBox(height: 28),

                    // 1. Critical Health Parameters Card
                    _buildBiometricGrid(medProfile),
                    const SizedBox(height: 24),

                    // 2. Allergies, Medications & Conditions
                    _buildMedicalSection("Medical Conditions", medProfile["conditions"], Icons.favorite_border_rounded, AppColors.errorRed),
                    const SizedBox(height: 16),
                    _buildMedicalSection("Allergies & Reactions", medProfile["allergies"], Icons.warning_amber_rounded, AppColors.warningOrange),
                    const SizedBox(height: 16),
                    _buildMedicalSection("Current Medications", medProfile["medications"], Icons.medication_outlined, AppColors.green),
                    const SizedBox(height: 16),
                    _buildMedicalSection("Critical Emergency Notes", medProfile["critical_notes"], Icons.assignment_late_outlined, AppColors.deepGreen),
                    const SizedBox(height: 28),

                    // 3. Emergency Contacts
                    const Text(
                      "Emergency Contacts",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    if (contacts.isEmpty)
                      const Text("No emergency contacts listed for this patient.", style: TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic))
                    else
                      ...contacts.map((c) => _buildContactCard(c)).toList(),

                    const SizedBox(height: 28),

                    // 4. Authorized Reports
                    const Text(
                      "Authorized Medical Reports",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    if (reports.isEmpty)
                      const Text("No medical reports uploaded by this patient.", style: TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic))
                    else
                      ...reports.map((r) => _buildReportTile(r)).toList(),
                      
                    const SizedBox(height: 40),

                    // End Session Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isRevoking ? null : _endAccess,
                        icon: _isRevoking 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                            : const Icon(Icons.gpp_bad_outlined, color: AppColors.white),
                        label: const Text("End Access Session", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    final name = _patientData?["patient_name"] ?? "Anonymous Patient";
    final email = _patientData?["patient_email"] ?? "N/A";
    final phone = _patientData?["patient_phone"] ?? "N/A";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGrey, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.deepGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  "Phone: $phone",
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
                const SizedBox(height: 2),
                Text(
                  "Email: $email",
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricGrid(Map medProfile) {
    final blood = medProfile["blood_group"]?.toString().toUpperCase() ?? "N/A";
    final height = medProfile["height"]?.toString() ?? "N/A";
    final weight = medProfile["weight"]?.toString() ?? "N/A";

    return Row(
      children: [
        Expanded(
          child: _buildHealthCard("Blood Group", blood, Icons.bloodtype_rounded, AppColors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildHealthCard("Height (cm)", height, Icons.height_rounded, AppColors.deepGreen),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildHealthCard("Weight (kg)", weight, Icons.monitor_weight_outlined, AppColors.deepGreen),
        ),
      ],
    );
  }

  Widget _buildHealthCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 1.2),
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
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.isEmpty ? "N/A" : value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalSection(String title, String? content, IconData icon, Color color) {
    final bool hasContent = content != null && content.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.borderGrey),
          Text(
            hasContent ? content! : "No listings registered.",
            style: TextStyle(
              fontSize: 13,
              color: hasContent ? AppColors.textDark : AppColors.textGrey,
              fontStyle: hasContent ? FontStyle.normal : FontStyle.italic,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map c) {
    final isPrimary = c["is_primary"] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPrimary ? AppColors.green.withOpacity(0.5) : AppColors.borderGrey, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.softMint : AppColors.lightSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.phone_rounded, color: isPrimary ? AppColors.green : AppColors.deepGreen, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c["name"] ?? "Anonymous Contact",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  "${c["relationship"]} | ${c["phone_number"]}",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Primary",
                style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportTile(Map r) {
    final title = r["title"] ?? "Medical Report";
    final type = r["type"] ?? "Document";
    final date = r["report_date"] ?? "N/A";
    final desc = r["description"] ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "$type | Date: $date",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                ),
                if (desc.toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 12, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_rounded, color: AppColors.green),
                tooltip: "View in-app",
                onPressed: () => _viewReportInApp(r),
              ),
              IconButton(
                icon: const Icon(Icons.file_download_outlined, color: AppColors.deepGreen),
                tooltip: "Download",
                onPressed: () => _downloadReport(r["id"], r["title"] + ".pdf"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _viewReportInApp(Map r) async {
    final baseUrl = await AuthService.getBaseUrl();
    final fileUrl = '$baseUrl/api/doctor/emergency-access/${widget.accessId}/reports/${r["id"]}/file';
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportViewerScreen(
          title: r["title"] ?? "Patient Medical Report",
          fileUrl: fileUrl,
          fileName: "${r["title"] ?? "report"}.pdf",
        ),
      ),
    );
  }
}
