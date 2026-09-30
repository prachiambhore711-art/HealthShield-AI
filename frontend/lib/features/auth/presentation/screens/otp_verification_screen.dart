import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/custom_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({Key? key}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();

  Timer? _timer;
  int _timerSeconds = 300;
  bool _canResend = false;
  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Add focus listeners to force state updates for border coloring
    for (var node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 300;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_timerSeconds > 0) {
          setState(() {
            _timerSeconds--;
          });
        } else {
          setState(() {
            _canResend = true;
          });
          _timer?.cancel();
        }
      }
    });
  }

  String _getMaskedDestination(String target) {
    if (target.contains("@")) {
      final parts = target.split("@");
      final local = parts[0];
      final domain = parts[1];
      if (local.length <= 3) {
        return "$local***@$domain";
      }
      return "${local.substring(0, 3)}***@$domain";
    } else {
      if (target.length <= 4) return target;
      return "${target.substring(0, 3)} XXXXX ${target.substring(target.length - 3)}";
    }
  }

  void _onResendOTP(String target, String purpose) async {
    if (!_canResend) return;

    setState(() {
      _errorMessage = "";
    });

    final result = await _authService.forgotPassword(target);
    if (result["success"]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A new OTP verification code has been dispatched."),
          backgroundColor: AppColors.successGreen,
        ),
      );
      _startTimer();
    } else {
      setState(() {
        _errorMessage = result["message"];
      });
    }
  }

  void _onVerify(String target, String purpose) async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() {
        _errorMessage = "Please enter the full 6-digit verification code.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final result = await _authService.verifyOtp(
      emailOrPhone: target,
      code: code,
      purpose: purpose,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result["success"]) {
      if (purpose == 'register') {
        // Registration success dialog matching Screen 11/12 redirect states
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Account Activated", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text("Your account was successfully verified and activated. You can now log in."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
                },
                child: const Text("Go to Login"),
              ),
            ],
          ),
        );
      } else {
        // Reset password flow
        Navigator.pushReplacementNamed(
          context,
          '/reset-password',
          arguments: {
            'email_or_phone': target,
            'code': code,
          },
        );
      }
    } else {
      setState(() {
        _errorMessage = result["message"];
      });
    }
  }

  Widget _buildOtpBox(int index) {
    final hasFocus = _focusNodes[index].hasFocus;
    return Container(
      constraints: const BoxConstraints(maxWidth: 46),
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFocus ? AppColors.green : AppColors.borderGrey,
          width: hasFocus ? 1.8 : 1.2,
        ),
        boxShadow: [
          if (hasFocus)
            BoxShadow(
              color: AppColors.green.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Center(
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            filled: false,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 5) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else {
                _focusNodes[index].unfocus();
              }
            } else {
              if (index > 0) {
                FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final purpose = args['purpose'] as String? ?? 'register';
    final target = args['target'] as String? ?? AuthService.cachedEmailOrPhone ?? '';

    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Heading
                Text(
                  "OTP Verification",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: "Enter the 6-digit code we sent to ",
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: _getMaskedDestination(target),
                        style: const TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Error Banner
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    6,
                    (index) => Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: _buildOtpBox(index),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Timer resend links
                Center(
                  child: _canResend
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Didn't receive code? ",
                              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () => _onResendOTP(target, purpose),
                              child: const Text(
                                "Resend OTP",
                                style: TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text.rich(
                          TextSpan(
                            text: "Didn't receive code? ",
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                            children: [
                              TextSpan(
                                text: "Resend OTP (${_timerSeconds.toString().padLeft(2, '0')})",
                                style: const TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 40),

                // Submit Button (Healthcare Green Gradient)
                CustomButton(
                  text: "Verify & Continue",
                  gradient: AppColors.primaryGradient,
                  isLoading: _isLoading,
                  onPressed: () => _onVerify(target, purpose),
                ),
                const SizedBox(height: 48),

                // Bottom Phone illustration Graphic
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.mint.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                           shape: BoxShape.circle,
                           boxShadow: [
                             BoxShadow(
                               color: Colors.black12,
                               blurRadius: 10,
                               offset: Offset(0, 4),
                             ),
                           ],
                        ),
                        child: const Icon(
                          Icons.phone_android_rounded,
                          size: 50,
                          color: AppColors.green,
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.deepGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 25,
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 24,
                          color: AppColors.green.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
