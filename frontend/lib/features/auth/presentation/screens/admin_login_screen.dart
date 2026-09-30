import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/server_config_dialog.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
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
      debugPrint("[AUTH_DEBUG] Admin _onLogin starting for: ${_emailController.text.trim()}");
      final result = await _authService.login(
        emailOrPhone: _emailController.text.trim(),
        password: _passwordController.text,
        role: "admin",
      );
      debugPrint("[AUTH_DEBUG] Admin _onLogin response: $result");

      if (!mounted) return;

      if (result["success"] == true) {
        final role = AuthService.userRole;
        if (role == "admin") {
          debugPrint("[AUTH_DEBUG] Admin login verified, committing autofill...");
          try {
            TextInput.finishAutofillContext(shouldSave: true);
          } catch (_) {}

          debugPrint("[AUTH_DEBUG] Navigating to /admin/dashboard");
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin/dashboard',
            (route) => false,
          );
        } else {
          // Clear cached credentials since they aren't admin
          AuthService.logout();
          try {
            TextInput.finishAutofillContext(shouldSave: false);
          } catch (_) {}
          setState(() {
            _errorMessage = "Access denied. This console is restricted to administrators only.";
          });
        }
      } else {
        try {
          TextInput.finishAutofillContext(shouldSave: false);
        } catch (_) {}
        setState(() {
          _errorMessage = result["message"]?.toString() ?? "Failed to authenticate console.";
        });
      }
    } catch (e, stackTrace) {
      debugPrint("[AUTH_DEBUG] Unexpected exception in Admin _onLogin: $e\n$stackTrace");
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
        debugPrint("[AUTH_DEBUG] Admin _isLoading set to false in finally block.");
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
                  // System Security Console Illustration
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.deepCharcoal,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.deepCharcoal.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/images/illustrations/login_admin.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: AppColors.green,
                              size: 40,
                            ),
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
                          "Admin Access",
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppColors.textDark,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Restricted System Console",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
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
                                  Icon(Icons.settings, size: 14, color: AppColors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    "Change Server IP / Settings",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.green,
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
                          labelText: "Admin Email",
                          hintText: "Enter administrative email",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.deepGreen),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Email is required";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          labelText: "Password",
                          hintText: "Enter admin password",
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.deepGreen),
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onLogin(),
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
                  const SizedBox(height: 36),
                  // Login Button
                  CustomButton(
                    text: "Authenticate Console",
                    gradient: const LinearGradient(
                      colors: [AppColors.deepCharcoal, AppColors.deepGreen],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    isLoading: _isLoading,
                    onPressed: _onLogin,
                  ),
                  const SizedBox(height: 24),
                  // Security Notice
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 6),
                        Text(
                          "Authorized personnel only. All access is logged.",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Security disclaimer
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 6),
                        Text(
                          "Administrative connection is securely encrypted.",
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
