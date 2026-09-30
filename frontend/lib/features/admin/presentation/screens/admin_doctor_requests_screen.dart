import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/admin_service.dart';

class AdminDoctorRequestsScreen extends StatefulWidget {
  const AdminDoctorRequestsScreen({Key? key}) : super(key: key);

  @override
  State<AdminDoctorRequestsScreen> createState() => _AdminDoctorRequestsScreenState();
}

class _AdminDoctorRequestsScreenState extends State<AdminDoctorRequestsScreen> {
  final _adminService = AdminService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];

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
      _loadRequests();
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    final results = await _adminService.getPendingDoctors();

    if (mounted) {
      setState(() {
        _requests = results;
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
          "Verification Requests",
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
          : _requests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  color: AppColors.deepGreen,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _requests.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _requests[index];
                      return _buildRequestTile(item);
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
              child: const Icon(Icons.mark_email_read_rounded, color: AppColors.textGrey, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              "All Caught Up!",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "There are no pending doctor registration requests requiring verification reviews right now.",
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

  Widget _buildRequestTile(Map<String, dynamic> item) {
    final doctorId = item["id"];
    final name = item["full_name"] ?? "Unknown Doctor";
    final email = item["email"] ?? "";
    final license = item["professional_id"] ?? "No License Entered";
    final specialty = item["specialization"] ?? "General Medicine";

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGrey, width: 1.2),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/admin/doctor-details',
            arguments: doctorId,
          ).then((_) => _loadRequests());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$specialty • $license",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textGrey, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
