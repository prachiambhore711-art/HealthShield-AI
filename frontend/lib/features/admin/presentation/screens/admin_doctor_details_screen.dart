import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/admin_service.dart';

class AdminDoctorDetailsScreen extends StatefulWidget {
  const AdminDoctorDetailsScreen({Key? key}) : super(key: key);

  @override
  State<AdminDoctorDetailsScreen> createState() => _AdminDoctorDetailsScreenState();
}

class _AdminDoctorDetailsScreenState extends State<AdminDoctorDetailsScreen> {
  final _adminService = AdminService();
  final _notesController = TextEditingController();
  bool _isLoading = true;
  Map<String, dynamic>? _doctor;
  String? _errorMessage;

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
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_doctor == null) {
      final doctorId = ModalRoute.of(context)!.settings.arguments as int;
      _fetchDoctorDetails(doctorId);
    }
  }

  Future<void> _fetchDoctorDetails(int doctorId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _adminService.getDoctorDetails(doctorId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result["success"]) {
          _doctor = result["doctor"];
        } else {
          _errorMessage = result["message"];
        }
      });
    }
  }

  Future<void> _showActionDialog(String actionTitle, Function(String) onConfirm) async {
    _notesController.clear();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            actionTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Are you sure you want to perform this action? Enter optional audit justification notes below:",
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Enter audit notes...",
                  hintStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppColors.textGrey)),
            ),
            ElevatedButton(
              onPressed: () {
                final notes = _notesController.text.trim();
                Navigator.pop(context);
                onConfirm(notes.isEmpty ? "Action performed by administrator" : notes);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  void _onVerify() {
    if (_doctor == null) return;
    _showActionDialog("Verify Doctor", (notes) async {
      setState(() => _isLoading = true);
      final result = await _adminService.verifyDoctor(_doctor!["id"], notes);
      if (mounted) {
        setState(() => _isLoading = false);
        if (result["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Doctor verified successfully"), backgroundColor: AppColors.successGreen),
          );
          _fetchDoctorDetails(_doctor!["id"]);
        } else {
          _showError(result["message"]);
        }
      }
    });
  }

  void _onReject() {
    if (_doctor == null) return;
    _showActionDialog("Reject Doctor Registration", (notes) async {
      setState(() => _isLoading = true);
      final result = await _adminService.rejectDoctor(_doctor!["id"], notes);
      if (mounted) {
        setState(() => _isLoading = false);
        if (result["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Doctor registration rejected"), backgroundColor: AppColors.errorRed),
          );
          _fetchDoctorDetails(_doctor!["id"]);
        } else {
          _showError(result["message"]);
        }
      }
    });
  }

  void _onSuspend() {
    if (_doctor == null) return;
    _showActionDialog("Suspend Doctor Account", (notes) async {
      setState(() => _isLoading = true);
      final result = await _adminService.suspendDoctor(_doctor!["id"], notes);
      if (mounted) {
        setState(() => _isLoading = false);
        if (result["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Doctor account suspended"), backgroundColor: AppColors.errorRed),
          );
          _fetchDoctorDetails(_doctor!["id"]);
        } else {
          _showError(result["message"]);
        }
      }
    });
  }

  void _onReactivate() {
    if (_doctor == null) return;
    _showActionDialog("Reactivate Doctor Account", (notes) async {
      setState(() => _isLoading = true);
      final result = await _adminService.reactivateDoctor(_doctor!["id"], notes);
      if (mounted) {
        setState(() => _isLoading = false);
        if (result["success"]) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Doctor account reactivated"), backgroundColor: AppColors.successGreen),
          );
          _fetchDoctorDetails(_doctor!["id"]);
        } else {
          _showError(result["message"]);
        }
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
    );
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
          "Doctor Profile Review",
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
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.errorRed)))
              : _buildDoctorDetails(),
    );
  }

  Widget _buildDoctorDetails() {
    if (_doctor == null) return const SizedBox();

    final name = _doctor!["full_name"] ?? "Unknown";
    final email = _doctor!["email"] ?? "";
    final phone = _doctor!["phone_number"] ?? "";
    final license = _doctor!["professional_id"] ?? "No License Entered";
    final specialty = _doctor!["specialization"] ?? "General Medicine";
    final status = _doctor!["doctor_verification_status"] ?? "pending";

    Color statusColor = AppColors.warningOrange;
    if (status == "verified") statusColor = AppColors.successGreen;
    if (status == "rejected" || status == "suspended") statusColor = AppColors.errorRed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Profile summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGrey, width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: AppColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services, color: AppColors.deepGreen, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Details List
          const Text(
            "Credential Information",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, "Email Address", email),
          _buildInfoRow(Icons.phone_outlined, "Phone Number", phone),
          _buildInfoRow(Icons.badge_outlined, "Medical License ID", license),
          _buildInfoRow(Icons.local_hospital_outlined, "Specialization", specialty),
          const SizedBox(height: 40),

          // Actions
          const Text(
            "Administrative Controls",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionControls(status),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textGrey, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControls(String status) {
    if (status == "pending") {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _onVerify,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text("Approve / Verify"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _onReject,
              icon: const Icon(Icons.highlight_off_rounded, size: 18),
              label: const Text("Reject"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    if (status == "verified") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onSuspend,
          icon: const Icon(Icons.warning_amber_rounded, size: 18),
          label: const Text("Suspend Account"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorRed,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    if (status == "suspended") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onReactivate,
          icon: const Icon(Icons.autorenew_rounded, size: 18),
          label: const Text("Reactivate / Verify"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successGreen,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    // Default or Rejected state
    return const Center(
      child: Text(
        "No further actions available for this profile status.",
        style: TextStyle(color: AppColors.textGrey, fontSize: 13),
      ),
    );
  }
}
