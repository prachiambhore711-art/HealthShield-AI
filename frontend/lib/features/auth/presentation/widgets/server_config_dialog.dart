import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _controller;
  bool _isTesting = false;
  String? _testResult;
  bool _isSuccess = false;

  final List<String> _presets = [
    "http://192.168.1.4:8000",
    "http://10.0.2.2:8000",
    "http://127.0.0.1:8000",
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AuthService.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final targetUrl = _controller.text.trim();
    final ok = await AuthService.testConnection(targetUrl);

    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _isSuccess = ok;
      _testResult = ok
          ? "Server reachable! Connection verified."
          : "Could not reach server. Verify IP & Wi-Fi.";
    });
  }

  Future<void> _save() async {
    final targetUrl = _controller.text.trim();
    if (targetUrl.isEmpty) return;

    await AuthService.setBaseUrl(targetUrl);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Server address updated to: ${AuthService.baseUrl}"),
        backgroundColor: AppColors.green,
      ),
    );
  }

  Future<void> _reset() async {
    await AuthService.resetBaseUrl();
    if (!mounted) return;
    setState(() {
      _controller.text = AuthService.baseUrl;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.wifi_tethering_rounded, color: AppColors.green),
          SizedBox(width: 10),
          Text(
            "Server Settings",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configure the backend API URL for this device:",
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: "API Base URL",
                hintText: "http://192.168.1.4:8000",
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Quick presets:",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _presets.map((preset) {
                return ActionChip(
                  label: Text(
                    preset.replaceAll("http://", ""),
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: AppColors.inputBackground,
                  onPressed: () {
                    setState(() {
                      _controller.text = preset;
                      _testResult = null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            if (_testResult != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? AppColors.successGreen.withOpacity(0.1)
                      : AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess
                        ? AppColors.successGreen.withOpacity(0.3)
                        : AppColors.errorRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _isSuccess ? AppColors.successGreen : AppColors.errorRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isSuccess ? AppColors.successGreen : AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check_rounded, size: 16),
              label: Text(_isTesting ? "Testing..." : "Test Connection"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _reset,
          child: const Text("Reset", style: TextStyle(color: AppColors.textGrey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text("Save & Apply"),
        ),
      ],
    );
  }
}
