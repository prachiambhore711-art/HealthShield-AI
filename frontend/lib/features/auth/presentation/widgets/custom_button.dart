import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;
  final double? width;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.gradient = AppColors.primaryGradient,
    this.backgroundColor = AppColors.green,
    this.textColor = AppColors.white,
    this.isLoading = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isLoading ? null : gradient,
        color: (isLoading || gradient != null) ? null : backgroundColor,
        boxShadow: [
          if (!isLoading)
            BoxShadow(
              color: (gradient != null 
                      ? AppColors.green.withOpacity(0.25)
                      : backgroundColor.withOpacity(0.2)),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
