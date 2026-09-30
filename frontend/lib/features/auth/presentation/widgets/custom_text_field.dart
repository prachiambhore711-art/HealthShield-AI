import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final String? labelText;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool? autocorrect;
  final bool? enableSuggestions;
  final ValueChanged<String>? onFieldSubmitted;

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.labelText,
    this.autofillHints,
    this.readOnly = false,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect,
    this.enableSuggestions,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            readOnly: readOnly,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            autocorrect: autocorrect ?? !obscureText,
            enableSuggestions: enableSuggestions ?? !obscureText,
            onFieldSubmitted: onFieldSubmitted,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: IconTheme(
                        data: const IconThemeData(color: AppColors.textGrey),
                        child: prefixIcon!,
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              suffixIcon: suffixIcon != null
                  ? IconTheme(
                      data: const IconThemeData(color: AppColors.textGrey),
                      child: suffixIcon!,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
