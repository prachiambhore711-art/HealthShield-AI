import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = "";

  void _onRegister(String role) async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final result = await _authService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        role: role,
      );

      if (!mounted) return;

      if (result["success"]) {
        try {
          TextInput.finishAutofillContext(shouldSave: true);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created! Verification OTP code has been sent to your email."),
            backgroundColor: AppColors.successGreen,
          ),
        );
        // Navigate to OTP Verification
        Navigator.pushReplacementNamed(
          context,
          '/verify-otp',
          arguments: {
            'purpose': 'register',
            'target': _emailController.text.trim(),
          },
        );
      } else {
        try {
          TextInput.finishAutofillContext(shouldSave: false);
        } catch (_) {}
        setState(() {
          _errorMessage = result["message"];
        });
      }
    } catch (e, stackTrace) {
      debugPrint("[AUTH_DEBUG] Unexpected exception in _onRegister: $e\n$stackTrace");
      try {
        TextInput.finishAutofillContext(shouldSave: false);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _errorMessage = "An unexpected error occurred: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                // Heading
                Text(
                  role == 'doctor' ? "Create Doctor Account" : "Create Patient Account",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  role == 'doctor'
                      ? "Register as a healthcare professional (Verification pending)."
                      : "Join us to manage your health better.",
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 28),

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
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form fields
                AutofillGroup(
                  child: Column(
                    children: [
                      // Name Input
                      CustomTextField(
                        labelText: "Full Name",
                        hintText: "Enter full name",
                        controller: _nameController,
                        prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textGrey),
                        autofillHints: const [AutofillHints.name],
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Full name is required";
                          }
                          if (val.trim().length < 2) {
                            return "Name must be at least 2 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Input
                      CustomTextField(
                        labelText: "Email Address",
                        hintText: "Enter email",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.textGrey),
                        autofillHints: const [AutofillHints.email, AutofillHints.username],
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Email address is required";
                          }
                          if (!RegExp(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$").hasMatch(val.trim())) {
                            return "Enter a valid email format";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Input
                      CustomTextField(
                        labelText: "Phone Number",
                        hintText: "Enter phone number",
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textGrey),
                        autofillHints: const [AutofillHints.telephoneNumber],
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Phone number is required";
                          }
                          // Basic check digits and options leading +
                          String clean = val.replaceAll(RegExp(r"\s+"), "");
                          if (!RegExp(r"^\+?[1-9]\d{9,14}$").hasMatch(clean)) {
                            return "Enter valid phone format (e.g. +919876543210)";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      CustomTextField(
                        labelText: "Password",
                        hintText: "Create password",
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textGrey),
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.next,
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
                          if (val == null || val.isEmpty) {
                            return "Password is required";
                          }
                          if (val.length < 8) {
                            return "Password must be at least 8 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password
                      CustomTextField(
                        labelText: "Confirm Password",
                        hintText: "Re-enter password",
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20, color: AppColors.textGrey),
                        autofillHints: const [AutofillHints.newPassword],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _onRegister(role),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textGrey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return "Confirm password is required";
                          }
                          if (val != _passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Register Button
                CustomButton(
                  text: "Register",
                  backgroundColor: primaryColor,
                  isLoading: _isLoading,
                  onPressed: () => _onRegister(role),
                ),
                const SizedBox(height: 24),

                // Login Redirect
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(color: AppColors.textDark, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/login', arguments: role);
                        },
                        child: Text(
                          "Login",
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
