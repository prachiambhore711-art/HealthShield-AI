import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({Key? key}) : super(key: key);

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  String _selectedSpecialization = "General Physician";
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String _errorMessage = "";

  final List<String> _specializations = [
    "General Physician",
    "General Practitioner",
    "Cardiologist",
    "Dentist",
    "Pediatrician",
    "Neurologist",
    "Orthopedic",
    "Oncologist"
  ];

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
      // Strip any leading Dr. prefix so actual name is stored without title duplication
      final rawName = _nameController.text.trim();
      final cleanName = rawName.replaceFirst(RegExp(r'^(dr\.?|doctor)\s+', caseSensitive: false), '').trim();

      final result = await _authService.register(
        fullName: cleanName.isNotEmpty ? cleanName : rawName,
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        role: 'doctor',
        specialization: _selectedSpecialization,
        professionalId: _licenseController.text.trim(),
      );

      if (!mounted) return;

      if (result["success"]) {
        try {
          TextInput.finishAutofillContext(shouldSave: true);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Doctor registration successful! OTP has been sent for account activation."),
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
      debugPrint("[AUTH_DEBUG] Unexpected exception in Doctor _onRegister: $e\n$stackTrace");
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
                    "Create Doctor Account",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Register as a healthcare professional",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Verification Card box matching Reference 6
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.veryLightMint,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.deepGreen.withOpacity(0.15), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.softMint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: AppColors.deepGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Professional Verification Required",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Your medical credentials will be reviewed by administrators before accessing patient medical files.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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

                        // Specialization Dropdown (Visual Only)
                        const Text(
                          "Specialization",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedSpecialization,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textGrey),
                          decoration: InputDecoration(
                            prefixIcon: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(Icons.stars_outlined, color: AppColors.textGrey),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            fillColor: AppColors.inputBackground,
                            filled: true,
                          ),
                          items: _specializations.map((String specialty) {
                            return DropdownMenuItem<String>(
                              value: specialty,
                              child: Text(specialty),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSpecialization = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Medical License ID (Visual Only)
                        CustomTextField(
                          labelText: "Medical License / ID",
                          hintText: "Enter license or registration ID",
                          controller: _licenseController,
                          prefixIcon: const Icon(Icons.badge_outlined),
                          textInputAction: TextInputAction.next,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Medical License ID is required";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Passwords
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

                  // Checkbox
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          activeColor: AppColors.deepGreen,
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
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepGreen),
                              ),
                              TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.deepGreen),
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
                    text: "Create Doctor Account",
                    gradient: AppColors.doctorGradient,
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
                            Navigator.pushNamed(context, '/login', arguments: 'doctor');
                          },
                          child: const Text(
                            "Login",
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
