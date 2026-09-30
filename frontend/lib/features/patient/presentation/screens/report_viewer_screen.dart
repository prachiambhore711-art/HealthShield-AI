import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import '../../../../core/theme/colors.dart';
import '../../../auth/data/auth_service.dart';

class ReportViewerScreen extends StatefulWidget {
  final String title;
  final String fileUrl;
  final String fileName;

  const ReportViewerScreen({
    Key? key,
    required this.title,
    required this.fileUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  State<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  File? _localFile;
  PdfControllerPinch? _pdfController;
  int _pdfTotalPages = 0;
  int _pdfCurrentPage = 1;

  bool get _isPdf => widget.fileName.toLowerCase().endsWith('.pdf');

  @override
  void initState() {
    super.initState();
    _downloadAndPrepareFile();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _downloadAndPrepareFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getSavedToken();
      final headers = {
        if (token != null) "Authorization": "Bearer $token",
      };

      final response = await http
          .get(Uri.parse(widget.fileUrl), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final ext = widget.fileName.contains('.')
            ? widget.fileName.substring(widget.fileName.lastIndexOf('.'))
            : (_isPdf ? '.pdf' : '.jpg');
        final tempPath = '${tempDir.path}/report_${DateTime.now().millisecondsSinceEpoch}$ext';
        final file = File(tempPath);
        await file.writeAsBytes(response.bodyBytes);

        if (_isPdf) {
          try {
            final document = await PdfDocument.openFile(file.path);
            _pdfTotalPages = document.pagesCount;
            _pdfController = PdfControllerPinch(
              document: Future.value(document),
            );
          } catch (pdfErr) {
            if (mounted) {
              setState(() {
                _errorMessage = "Unable to render PDF document: $pdfErr";
                _isLoading = false;
              });
            }
            return;
          }
        }

        if (mounted) {
          setState(() {
            _localFile = file;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 403) {
        if (mounted) {
          setState(() {
            _errorMessage = "Access Restricted: You are not authorized to view this report, or the emergency session has expired.";
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            _errorMessage = "The requested medical report file was not found on the server.";
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Server returned status ${response.statusCode} while loading report.";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Network error loading report: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepCharcoal,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_isPdf && _pdfTotalPages > 0)
              Text(
                "Page $_pdfCurrentPage of $_pdfTotalPages",
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
          ],
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.green),
                  SizedBox(height: 16),
                  Text("Loading report securely...", style: TextStyle(color: AppColors.white, fontSize: 13)),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildViewer(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.errorRed, size: 56),
            const SizedBox(height: 20),
            const Text(
              "Unable to Open Report",
              style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? "An unknown error occurred.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _downloadAndPrepareFile,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.white, size: 18),
              label: const Text("Retry", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer() {
    if (_localFile == null) {
      return const Center(child: Text("File not loaded", style: TextStyle(color: AppColors.white)));
    }

    if (_isPdf && _pdfController != null) {
      return PdfViewPinch(
        controller: _pdfController!,
        onPageChanged: (page) {
          if (mounted) setState(() => _pdfCurrentPage = page);
        },
        backgroundDecoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
      );
    } else {
      // Image viewing with interactive pinch-to-zoom
      return PhotoView(
        imageProvider: FileImage(_localFile!),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3.0,
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: AppColors.green),
        ),
      );
    }
  }
}
