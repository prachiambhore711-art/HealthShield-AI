import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import 'package:frontend/features/patient/data/patient_service.dart';

class EmergencyQrScreen extends StatefulWidget {
  final bool isNavigatedFromNavBar;

  const EmergencyQrScreen({
    Key? key,
    this.isNavigatedFromNavBar = false,
  }) : super(key: key);

  @override
  State<EmergencyQrScreen> createState() => _EmergencyQrScreenState();
}

class _EmergencyQrScreenState extends State<EmergencyQrScreen> {
  final _patientService = PatientService();
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isSharing = false;
  String? _errorMessage;
  String? _qrToken;

  Future<Uint8List?> _generateQrBytes(String token) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: token,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        );
        final imageData = await painter.toImageData(300);
        return imageData?.buffer.asUint8List();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _downloadQr() async {
    if (_qrToken == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final bytes = await _generateQrBytes(_qrToken!);
      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = await File('${tempDir.path}/healthshield_qr_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await tempFile.writeAsBytes(bytes);

        // Check/request permission using Gal API
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          final granted = await Gal.requestAccess();
          if (!granted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Permission Denied: Storage/Gallery access is required to download the QR code."),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
            return;
          }
        }

        // Save to Gallery
        await Gal.putImage(tempFile.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("QR Code saved successfully to your device Photos/Gallery!"),
              backgroundColor: AppColors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception("Failed to render QR code image bytes");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving QR Code: $e"),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _shareQr() async {
    if (_qrToken == null) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final bytes = await _generateQrBytes(_qrToken!);
      if (bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/healthshield_emergency_qr.png').create();
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: "HealthShield AI - Emergency QR Code Opaque Token",
        );
      } else {
        throw Exception("Failed to render QR code image bytes");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sharing QR Code: $e"),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQrToken();
  }

  Future<void> _loadQrToken() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _patientService.getEmergencyQr();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result["success"]) {
          _qrToken = result["qr"]["token"];
        } else {
          _errorMessage = result["message"];
        }
      });
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
            "My Emergency QR",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.green),
              onPressed: _loadQrToken,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadQrToken,
                icon: const Icon(Icons.refresh, color: AppColors.white),
                label: const Text("Retry", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                  iconColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // 1. QR Code Card Container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderGrey, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Render local QR representation using qr_flutter
                if (_qrToken != null) ...[
                  QrImageView(
                    data: _qrToken!,
                    version: QrVersions.auto,
                    size: 240,
                    gapless: false,
                    foregroundColor: AppColors.textDark,
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  "Scan QR Code",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Keep this QR accessible. Scanning will request emergency medical records.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
                if (_qrToken != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderGrey.withOpacity(0.8)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Emergency Token:",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textGrey,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              SelectableText(
                                _qrToken!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: AppColors.green, size: 20),
                          tooltip: "Copy Token",
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _qrToken!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Emergency Token copied to clipboard!"),
                                backgroundColor: AppColors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 2. Info Warning Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.green.withOpacity(0.3), width: 1.2),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_rounded, color: AppColors.deepGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Opaque Token Verification",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepGreen,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "The QR contains ONLY a secure identifier token. The backend verifies doctor authority before exposing any medical records.",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textGrey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // 3. Share/Download actual buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadQr,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded, color: AppColors.white),
                    label: Text(
                      _isDownloading ? "Saving..." : "Download QR",
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isSharing ? null : _shareQr,
                    icon: _isSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded, color: AppColors.green),
                    label: Text(
                      _isSharing ? "Sharing..." : "Share QR",
                      style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.green, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
