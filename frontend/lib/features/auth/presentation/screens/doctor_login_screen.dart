import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/server_config_dialog.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({Key? key}) : super(key: key);

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = "";

  void _onLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      debugPrint("[AUTH_DEBUG] Doctor _onLogin starting for: ${_identifierController.text.trim()}");
      final result = await _authService.login(
        emailOrPhone: _identifierController.text.trim(),
        password: _passwordController.text,
        role: "doctor",
      );
      debugPrint("[AUTH_DEBUG] Doctor _onLogin response: $result");

      if (!mounted) return;

      if (result["success"] == true) {
        debugPrint("[AUTH_DEBUG] Doctor login succeeded, committing autofill context...");
        try {
          TextInput.finishAutofillContext(shouldSave: true);
        } catch (_) {}

        final userRole = result["data"]?["role"] ?? AuthService.userRole;
        String targetRoute = '/doctor/dashboard';
        if (userRole == 'patient') {
          targetRoute = '/patient/dashboard';
        } else if (userRole == 'admin') {
          targetRoute = '/admin/dashboard';
        }

        debugPrint("[AUTH_DEBUG] Navigating to $targetRoute");
        Navigator.pushNamedAndRemoveUntil(
          context,
          targetRoute,
          (route) => false,
        );
      } else {
        try {
          TextInput.finishAutofillContext(shouldSave: false);
        } catch (_) {}

        final message = result["message"]?.toString() ?? "Failed to login.";
        if (message.contains("inactive") || message.contains("OTP has been sent")) {
          AuthService.cachedEmailOrPhone = _identifierController.text.trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.warningOrange,
            ),
          );
          Navigator.pushNamed(
            context,
            '/verify-otp',
            arguments: {'purpose': 'register', 'target': _identifierController.text.trim()},
          );
        } else {
          setState(() {
            _errorMessage = message;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint("[AUTH_DEBUG] Unexpected exception in Doctor _onLogin: $e\n$stackTrace");
      try {
        TextInput.finishAutofillContext(shouldSave: false);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _errorMessage = "An unexpected error occurred. Please try again: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        debugPrint("[AUTH_DEBUG] Doctor _isLoading set to false in finally block.");
      }
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.wifi_tethering_rounded, color: AppColors.textDark),
              tooltip: "Server Settings",
              onPressed: () => ServerConfigDialog.show(context),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Centered Circular Doctor Illustration
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.softMint,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepGreen.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/illustrations/login_doctor.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.medical_services_outlined,
                            color: AppColors.deepGreen,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title & Subtitle
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Welcome Doctor",
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Login to your clinical practitioner portal",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Error Message Banner
                  if (_errorMessage.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                          ),
                          if (_errorMessage.toLowerCase().contains("connect") ||
                              _errorMessage.toLowerCase().contains("timeout") ||
                              _errorMessage.toLowerCase().contains("server") ||
                              _errorMessage.toLowerCase().contains("unable")) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => ServerConfigDialog.show(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.settings, size: 14, color: AppColors.deepGreen),
                                  SizedBox(width: 4),
                                  Text(
                                    "Change Server IP / Settings",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.deepGreen,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Fields
                  AutofillGroup(
                    child: Column(
                      children: [
                        CustomTextField(
                          labelText: "Email or Phone Number",
                          hintText: "Enter email or phone number",
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.deepGreen),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Email or phone is required";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          labelText: "Password",
                          hintText: "Enter your password",
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.deepGreen),
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onLogin(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textGrey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Password is required";
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: AppColors.deepGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Login Button
                  CustomButton(
                    text: "Login as Doctor",
                    gradient: AppColors.doctorGradient,
                    isLoading: _isLoading,
                    onPressed: _onLogin,
                  ),
                  const SizedBox(height: 32),
                  // Register redirect link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/doctor-register');
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              color: AppColors.deepGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Professional verification disclaimer
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 6),
                        Text(
                          "Verification required for patient data access.",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
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
      ),
    );
  }
}
