import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = "";

  // Password requirements validation state
  bool _hasMinLength = false;
  bool _hasUpperLower = false;
  bool _hasNumberOrSpecial = false;

  // Password strength visual states
  double _strengthValue = 0.0;
  Color _strengthColor = AppColors.errorRed;
  String _strengthText = "";

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordRequirements);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordRequirements);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordRequirements() {
    final text = _passwordController.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasUpperLower = text.contains(RegExp(r'[A-Z]')) && text.contains(RegExp(r'[a-z]'));
      _hasNumberOrSpecial = text.contains(RegExp(r'[0-9]')) || text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      // Calculate strength
      if (text.isEmpty) {
        _strengthValue = 0.0;
        _strengthText = "";
      } else {
        int score = 0;
        if (_hasMinLength) score++;
        if (_hasUpperLower) score++;
        if (_hasNumberOrSpecial) score++;
        _strengthValue = score / 3.0;

        if (score == 1) {
          _strengthColor = AppColors.errorRed;
          _strengthText = "Weak";
        } else if (score == 2) {
          _strengthColor = AppColors.warningOrange;
          _strengthText = "Medium";
        } else if (score == 3) {
          _strengthColor = AppColors.green;
          _strengthText = "Strong";
        }
      }
    });
  }

  void _onResetPassword(String emailOrPhone, String code) async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    
    if (!_hasMinLength || !_hasUpperLower || !_hasNumberOrSpecial) {
      setState(() {
        _errorMessage = "Password does not meet the safety requirements.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final result = await _authService.resetPassword(
        emailOrPhone: emailOrPhone,
        code: code,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (result["success"]) {
        try {
          TextInput.finishAutofillContext(shouldSave: true);
        } catch (_) {}
        setState(() {
          _isSuccess = true;
        });
      } else {
        try {
          TextInput.finishAutofillContext(shouldSave: false);
        } catch (_) {}
        setState(() {
          _errorMessage = result["message"];
        });
      }
    } catch (e, stackTrace) {
      debugPrint("[AUTH_DEBUG] Unexpected exception in _onResetPassword: $e\n$stackTrace");
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

  Widget _buildRequirementRow(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: isValid ? AppColors.green : AppColors.textGrey.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isValid ? AppColors.green : AppColors.textGrey,
              fontWeight: isValid ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final emailOrPhone = args['email_or_phone'] as String? ?? '';
    final code = args['code'] as String? ?? '';

    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: !_isSuccess
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _isSuccess
                ? _buildSuccessView()
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Header
                        Text(
                          "Create New Password",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Your new password must be different from previous used passwords.",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Error banner
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

                        // Password fields
                        AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                labelText: "New Password",
                                hintText: "Enter new password",
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                autofillHints: const [AutofillHints.newPassword],
                                textInputAction: TextInputAction.next,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return "New password is required";
                                  }
                                  return null;
                                },
                              ),
                              
                              // Password strength segment bar
                              if (_passwordController.text.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: _strengthValue,
                                          backgroundColor: AppColors.borderGrey,
                                          color: _strengthColor,
                                          minHeight: 5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Password strength: $_strengthText",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _strengthColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
                              
                              CustomTextField(
                                labelText: "Confirm Password",
                                hintText: "Confirm new password",
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                prefixIcon: const Icon(Icons.lock_clock_outlined),
                                autofillHints: const [AutofillHints.newPassword],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _onResetPassword(emailOrPhone, code),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return "Please confirm your password";
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
                        const SizedBox(height: 24),

                        // Requirements list
                        const Text(
                          "Password requirements:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRequirementRow("At least 8 characters", _hasMinLength),
                        _buildRequirementRow("Include uppercase & lowercase", _hasUpperLower),
                        _buildRequirementRow("Include number or special character", _hasNumberOrSpecial),
                        const SizedBox(height: 36),

                        // Submit button
                        CustomButton(
                          text: "Reset Password",
                          isLoading: _isLoading,
                          onPressed: () => _onResetPassword(emailOrPhone, code),
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

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          // Checkmark circular decoration
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 100,
                height: 100,
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
                  Icons.check_circle_rounded,
                  size: 56,
                  color: AppColors.green,
                ),
              ),
              Positioned(
                right: 15,
                top: 15,
                child: Icon(Icons.star_rounded, size: 16, color: AppColors.warningOrange.withOpacity(0.6)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Success texts
          Text(
            "Password Reset Successful!",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Your password has been reset successfully.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Back to Login Button
          CustomButton(
            text: "Back to Login",
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
