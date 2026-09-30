import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/server_config_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = "";

  void _onLogin(String role) async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      debugPrint("[AUTH_DEBUG] General Login _onLogin starting for: ${_identifierController.text.trim()} (role: $role)");
      final result = await _authService.login(
        emailOrPhone: _identifierController.text.trim(),
        password: _passwordController.text,
        role: role,
      );
      debugPrint("[AUTH_DEBUG] General Login _onLogin response: $result");

      if (!mounted) return;

      if (result["success"] == true) {
        debugPrint("[AUTH_DEBUG] General Login succeeded, committing autofill context...");
        try {
          TextInput.finishAutofillContext(shouldSave: true);
        } catch (_) {}

        final userRole = result["data"]?["role"] ?? role;
        String targetRoute = '/patient/dashboard';
        if (userRole == 'doctor') {
          targetRoute = '/doctor/dashboard';
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
      debugPrint("[AUTH_DEBUG] Unexpected exception in General Login: $e\n$stackTrace");
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
        debugPrint("[AUTH_DEBUG] General Login _isLoading reset in finally block.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get selected role parameter
    final role = ModalRoute.of(context)?.settings.arguments as String? ?? 'patient';
    final primaryColor = role == 'doctor' ? AppColors.deepGreen : AppColors.green;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
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
                const SizedBox(height: 10),
                // Logo
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 52,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.shield,
                      size: 40,
                      color: AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Patient Soft-3D Illustration
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.veryLightMint,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/illustrations/login_patient.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.person,
                          size: 50,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title
                Center(
                  child: Text(
                    "Welcome Back",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textDark,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    "Sign in as ${role.toUpperCase()}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Error Message block
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
                              children: [
                                Icon(Icons.settings, size: 14, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  "Change Server IP / Settings",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
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

                // Inputs
                AutofillGroup(
                  child: Column(
                    children: [
                      CustomTextField(
                        labelText: "Email or Phone Number",
                        hintText: "Enter email or phone",
                        controller: _identifierController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.username, AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textGrey),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Email or Phone number is required";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        labelText: "Password",
                        hintText: "Enter password",
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textGrey),
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onLogin(role),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textGrey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Password is required";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Login Button
                CustomButton(
                  text: "Login",
                  backgroundColor: primaryColor,
                  isLoading: _isLoading,
                  onPressed: () => _onLogin(role),
                ),
                const SizedBox(height: 32),
                // Register Redirect
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: AppColors.textDark, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/register', arguments: role);
                        },
                        child: Text(
                          "Register",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
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
