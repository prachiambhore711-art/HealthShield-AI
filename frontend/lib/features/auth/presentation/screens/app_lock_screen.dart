import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/services/app_lock_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;

  const AppLockScreen({Key? key, this.onUnlocked}) : super(key: key);

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = "";
  bool _isVerifying = false;
  String? _errorMessage;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkAndPromptBiometrics();
  }

  Future<void> _checkAndPromptBiometrics() async {
    final enabled = await AppLockService.isBiometricsEnabled();
    final hardwareOk = await AppLockService.canCheckBiometrics();
    if (mounted) {
      setState(() {
        _canUseBiometrics = enabled && hardwareOk;
      });
    }

    if (_canUseBiometrics) {
      // Trigger biometrics automatically on display
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (!mounted) return;
        final success = await AppLockService.authenticateWithBiometrics();
        if (success && mounted) {
          _onSuccess();
        }
      });
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4 && !_isVerifying) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty && !_isVerifying) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);
    final isCorrect = await AppLockService.verifyPin(_enteredPin);
    if (!mounted) return;

    if (isCorrect) {
      _onSuccess();
    } else {
      setState(() {
        _enteredPin = "";
        _isVerifying = false;
        _errorMessage = "Incorrect PIN. Please try again.";
      });
    }
  }

  void _onSuccess() {
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Must authenticate to pass
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // Shield Icon
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.deepGreen,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "HealthShield Protected",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your 4-digit App PIN to access private records",
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
              const SizedBox(height: 32),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.green : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? AppColors.green : AppColors.borderGrey,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Error message
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontWeight: FontWeight.bold),
                )
              else
                const SizedBox(height: 16),

              const Spacer(),

              // Numeric Keypad
              _buildKeypad(),
              const SizedBox(height: 24),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/patient/qr');
                },
                icon: const Icon(Icons.qr_code_rounded, size: 18, color: AppColors.green),
                label: const Text("Show Emergency QR", style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildKey("1"), _buildKey("2"), _buildKey("3")],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildKey("4"), _buildKey("5"), _buildKey("6")],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildKey("7"), _buildKey("8"), _buildKey("9")],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _canUseBiometrics
                  ? IconButton(
                      icon: const Icon(Icons.fingerprint_rounded, size: 36, color: AppColors.deepGreen),
                      onPressed: () async {
                        final success = await AppLockService.authenticateWithBiometrics();
                        if (success && mounted) _onSuccess();
                      },
                    )
                  : const SizedBox(width: 64, height: 64),
              _buildKey("0"),
              IconButton(
                icon: const Icon(Icons.backspace_outlined, size: 26, color: AppColors.textDark),
                onPressed: _onBackspace,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String digit) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderGrey.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
    );
  }
}
