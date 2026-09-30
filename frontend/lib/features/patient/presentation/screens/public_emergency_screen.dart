import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/data/auth_service.dart';

class PublicEmergencyScreen extends StatefulWidget {
  final String token;

  const PublicEmergencyScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<PublicEmergencyScreen> createState() => _PublicEmergencyScreenState();
}

class _PublicEmergencyScreenState extends State<PublicEmergencyScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _emergencyData;

  @override
  void initState() {
    super.initState();
    _fetchPublicEmergencyData();
  }

  Future<void> _fetchPublicEmergencyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final baseUrl = await AuthService.getBaseUrl();
      final uri = Uri.parse('$baseUrl/api/public/emergency/${Uri.encodeComponent(widget.token.trim())}');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _emergencyData = data;
            _isLoading = false;
          });
        }
      } else {
        final err = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _errorMessage = err['detail'] ?? 'Emergency QR is invalid or revoked.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not connect to emergency server: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _callContact(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Cannot launch phone dialer for: $cleanPhone")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error launching dialer: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Emergency Medical ID",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textDark, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.errorRed))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildEmergencyCard(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.softEmergencyBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gpp_bad_rounded, size: 56, color: AppColors.errorRed),
            ),
            const SizedBox(height: 24),
            const Text(
              "Access Restricted",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? "This emergency QR is inactive or invalid.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchPublicEmergencyData,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
              label: const Text("Retry", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard() {
    final String firstName = _emergencyData?['first_name'] ?? 'Patient';
    final String bloodGroup = _emergencyData?['blood_group'] ?? 'Unknown';
    final String? criticalWarning = _emergencyData?['critical_allergy_warning'];
    final Map<String, dynamic>? primaryContact = _emergencyData?['primary_contact'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emergency Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.errorRed,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services_rounded, color: AppColors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "EMERGENCY INFORMATION",
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Public first-responder minimal medical ID",
                        style: TextStyle(color: AppColors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Patient Name & Blood Group Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PATIENT", style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      firstName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.softEmergencyBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.errorRed.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      const Text("BLOOD GROUP", style: TextStyle(fontSize: 9, color: AppColors.errorRed, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        bloodGroup,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.errorRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Critical Allergy Warning (if marked emergency-critical)
          if (criticalWarning != null && criticalWarning.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // Amber soft background
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warningOrange.withOpacity(0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "CRITICAL ALLERGY / MEDICAL ALERT",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warningOrange),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          criticalWarning,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Primary Emergency Contact Card
          if (primaryContact != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "PRIMARY EMERGENCY CONTACT",
                        style: TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          primaryContact['relationship'] ?? 'Contact',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.deepGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    primaryContact['name'] ?? 'Emergency Contact',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    primaryContact['phone_number'] ?? '',
                    style: const TextStyle(fontSize: 15, color: AppColors.textGrey, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _callContact(primaryContact['phone_number'] ?? ''),
                      icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.white),
                      label: const Text(
                        "Call Emergency Contact",
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: const Text(
                "No primary emergency contact specified.",
                style: TextStyle(color: AppColors.textGrey, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
