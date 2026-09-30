import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../data/doctor_service.dart';
import 'doctor_patient_emergency_profile_screen.dart';

class DoctorQrScannerScreen extends StatefulWidget {
  const DoctorQrScannerScreen({Key? key}) : super(key: key);

  @override
  State<DoctorQrScannerScreen> createState() => _DoctorQrScannerScreenState();
}

class _DoctorQrScannerScreenState extends State<DoctorQrScannerScreen> with SingleTickerProviderStateMixin {
  final DoctorService _doctorService = DoctorService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tokenController = TextEditingController();
  late final MobileScannerController _scannerController;
  
  bool _isLoading = false;
  bool _isProcessingCode = false;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessingCode || _isLoading) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _isProcessingCode = true;
        _tokenController.text = rawValue.trim();
        _submitToken(rawValue.trim());
        break;
      }
    }
  }

  Future<void> _submitToken(String token) async {
    if (token.trim().isEmpty) {
      _isProcessingCode = false;
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _doctorService.requestEmergencyAccess(token.trim());
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res["success"] == true) {
      final accessId = res["access_id"];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res["message"] ?? "Access granted!"),
          backgroundColor: AppColors.successGreen,
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorPatientEmergencyProfileScreen(accessId: accessId),
        ),
      );
      if (mounted) {
        setState(() {
          _isProcessingCode = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = res["message"] ?? "Failed to grant emergency access.";
        _isProcessingCode = false;
      });
    }
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
          "Scanner",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Live Camera Viewfinder Frame with Overlay
            Center(
              child: Container(
                width: 280,
                height: 280,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.deepGreen, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Real Live Camera Feed via MobileScanner
                    Positioned.fill(
                      child: MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                        errorBuilder: (context, error) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Camera unavailable: ${error.errorCode.name}\nPlease grant camera permission or use manual input below.",
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Outer targeting brackets
                    _buildCornerBorder(Alignment.topLeft),
                    _buildCornerBorder(Alignment.topRight),
                    _buildCornerBorder(Alignment.bottomLeft),
                    _buildCornerBorder(Alignment.bottomRight),

                    // Laser scan animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Positioned(
                          top: 20 + (_animationController.value * 235),
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.green.withOpacity(0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Scanning feedback indicator
                    if (_isProcessingCode || _isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.55),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppColors.green),
                              SizedBox(height: 12),
                              Text(
                                "Verifying QR Token...",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Camera Controls: Flashlight & Camera Flip
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: () => _scannerController.toggleTorch(),
                  icon: const Icon(Icons.flash_on_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.deepGreen,
                  ),
                  tooltip: "Toggle Flash",
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  onPressed: () => _scannerController.switchCamera(),
                  icon: const Icon(Icons.flip_camera_ios_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.deepGreen,
                  ),
                  tooltip: "Switch Camera",
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Help instruction text
            const Text(
              "Position the Patient's HealthShield AI QR Code in the frame to scan automatically.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
            ),
            const SizedBox(height: 28),

            // Token Input Section (Fallback/Manual Entry)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderGrey, width: 1.2),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter Opaque QR Token Manually",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _tokenController,
                      hintText: "e.g. HS-E:token_value",
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Token is required";
                        }
                        if (!val.trim().startsWith("HS-E:")) {
                          return "Invalid format: Must start with 'HS-E:'";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                    ],
                    CustomButton(
                      text: "Resolve Token & Access",
                      gradient: AppColors.doctorGradient,
                      isLoading: _isLoading,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _submitToken(_tokenController.text);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBorder(Alignment alignment) {
    bool isTop = alignment == Alignment.topLeft || alignment == Alignment.topRight;
    bool isLeft = alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: AppColors.deepGreen, width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: AppColors.deepGreen, width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: AppColors.deepGreen, width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: AppColors.deepGreen, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
