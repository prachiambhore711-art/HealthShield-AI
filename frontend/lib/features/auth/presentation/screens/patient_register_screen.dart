import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({Key? key}) : super(key: key);

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
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
  bool _agreedToTerms = false;
  String _errorMessage = "";

  // Password strength visual states
  double _strengthValue = 0.0;
  Color _strengthColor = AppColors.errorRed;
  String _strengthText = "";

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_calculatePasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_calculatePasswordStrength);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _calculatePasswordStrength() {
    final text = _passwordController.text;
    if (text.isEmpty) {
      setState(() {
        _strengthValue = 0.0;
        _strengthText = "";
      });
      return;
    }

    int score = 0;
    if (text.length >= 8) score++;
    if (text.contains(RegExp(r'[A-Z]')) && text.contains(RegExp(r'[a-z]'))) score++;
    if (text.contains(RegExp(r'[0-9]')) || text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    setState(() {
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
    });
  }

  void _onRegister() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = "You must agree to the Terms and Conditions to proceed.";
      });
      return;
    }

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
        role: 'patient',
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
      debugPrint("[AUTH_DEBUG] Unexpected exception in Patient _onRegister: $e\n$stackTrace");
      try {
        TextInput.finishAutofillContext(shouldSave: false);
      } catch (_) {}
      if (mounted) {
        setState(() {
          _errorMessage = "An unexpected error occurred during registration: $e";
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Heading
                  Text(
                    "Create Patient Account",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Fill in your details to create account",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

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
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: AppColors.errorRed, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form Fields
                  AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          labelText: "Full Name",
                          hintText: "Enter your full name",
                          controller: _nameController,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
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
                        CustomTextField(
                          labelText: "Email",
                          hintText: "Enter your email address",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
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
                        CustomTextField(
                          labelText: "Phone Number",
                          hintText: "Enter your phone number",
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_outlined),
                          autofillHints: const [AutofillHints.telephoneNumber],
                          textInputAction: TextInputAction.next,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Phone number is required";
                            }
                            String clean = val.replaceAll(RegExp(r"\s+"), "");
                            if (!RegExp(r"^\+?[1-9]\d{9,14}$").hasMatch(clean)) {
                              return "Enter valid phone format (e.g. +919876543210)";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          labelText: "Password",
                          hintText: "Create a password",
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
                              return "Password is required";
                            }
                            if (val.length < 8) {
                              return "Password must be at least 8 characters";
                            }
                            return null;
                          },
                        ),
                        
                        // Password strength visual indicator
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
                          hintText: "Confirm your password",
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onRegister(),
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
                  const SizedBox(height: 20),
                  
                  // Terms and conditions checkbox row
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppColors.green,
                          onChanged: (val) {
                            setState(() {
                              _agreedToTerms = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: "I agree to the ",
                            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                            children: [
                              TextSpan(
                                text: "Terms & Conditions",
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green),
                              ),
                              TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  CustomButton(
                    text: "Create Account",
                    isLoading: _isLoading,
                    onPressed: _onRegister,
                  ),
                  const SizedBox(height: 28),
                  
                  // Login redirect link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/login', arguments: 'patient');
                          },
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: AppColors.green,
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
      ),
    );
  }
}
