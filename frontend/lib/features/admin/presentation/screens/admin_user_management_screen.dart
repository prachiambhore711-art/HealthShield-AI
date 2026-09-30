import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/admin_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _adminService = AdminService();
  final _searchController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedRole = ""; // "" means All
  List<Map<String, dynamic>> _users = [];

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
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    final results = await _adminService.searchUsers(
      query: _searchController.text.trim(),
      role: _selectedRole.isEmpty ? null : _selectedRole,
    );

    if (mounted) {
      setState(() {
        _users = results;
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
          "User Directory",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter header block
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: "Search by name or email...",
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGrey, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: const Color(0xFFF3F3F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Role Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("All", ""),
                      const SizedBox(width: 8),
                      _buildFilterChip("Patients", "patient"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Doctors", "doctor"),
                      const SizedBox(width: 8),
                      _buildFilterChip("Admins", "admin"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.deepGreen),
                  )
                : _users.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _performSearch,
                        color: AppColors.deepGreen,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _users.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return _buildUserTile(user);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String roleValue) {
    final isSelected = _selectedRole == roleValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedRole = roleValue;
          });
          _performSearch();
        }
      },
      selectedColor: AppColors.deepGreen.withOpacity(0.12),
      backgroundColor: const Color(0xFFF3F3F7),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.deepGreen : AppColors.textDark,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_alt_outlined, color: AppColors.textGrey, size: 48),
            const SizedBox(height: 16),
            const Text(
              "No Users Found",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try searching by another name or adjust your filter.",
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

  Widget _buildUserTile(Map<String, dynamic> user) {
    final name = user["full_name"] ?? "Unknown";
    final email = user["email"] ?? "";
    final role = user["role"] ?? "patient";
    final isDoctor = role == "doctor";
    final isAdmin = role == "admin";
    
    Color roleColor = AppColors.green; // Patient
    if (isDoctor) roleColor = AppColors.deepGreen;
    if (isAdmin) roleColor = AppColors.deepCharcoal;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderGrey, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : isDoctor
                        ? Icons.medical_services_rounded
                        : Icons.person_rounded,
                color: roleColor,
                size: 22,
              ),
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
                    email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: roleColor,
                          ),
                        ),
                      ),
                      if (isDoctor) ...[
                        const SizedBox(width: 8),
                        Text(
                          "Status: ${user['doctor_verification_status'] ?? 'pending'}",
                          style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
