import 'package:flutter/material.dart';

class AppColors {
  // 1. Primary Clinical Green
  static const Color green = Color(0xFF10B981);             // Primary Healthcare Green
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color deepGreen = Color(0xFF047857);         // Deep clinical green
  static const Color darkClinicalGreen = Color(0xFF065F46); // Dark clinical green
  static const Color mint = Color(0xFFD1FAE5);              // Soft Mint
  static const Color softMint = Color(0xFFD1FAE5);
  static const Color veryLightMint = Color(0xFFECFDF5);     // Very Light Mint

  // 2. Baby Pink / AI Identity Accent (Replaces Purple)
  static const Color babyPink = Color(0xFFF9A8D4);          // Elegant Baby Pink
  static const Color softPink = Color(0xFFFCE7F3);          // Soft Pink surface/chip
  static const Color lightestPink = Color(0xFFFFF1F7);      // Lightest Pink background
  static const Color pink = Color(0xFFEC4899);              // Premium Pink action/accent
  static const Color premiumPink = Color(0xFFEC4899);
  static const Color deepPink = Color(0xFFDB2777);          // Deep Pink accent/gradient

  // 3. Emergency Red
  static const Color errorRed = Color(0xFFEF4444);          // Emergency Red
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color darkEmergencyRed = Color(0xFFDC2626);
  static const Color softEmergencyBg = Color(0xFFFEF2F2);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);

  // 4. Neutral System
  static const Color background = Color(0xFFF8FAFC);         // Clean Canvas Background
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A);          // Primary Text Navy/Charcoal
  static const Color textSecondary = Color(0xFF475569);     // Secondary Text
  static const Color textGrey = Color(0xFF64748B);          // Muted Body Text
  static const Color borderGrey = Color(0xFFE2E8F0);        // Card/Input Border Grey
  static const Color lightSurface = Color(0xFFF1F5F9);      // Light Surface Grey
  static const Color inputBackground = Color(0xFFFFFFFF);   // Pure white input field surface
  static const Color deepCharcoal = Color(0xFF1E293B);      // Deep Operational Charcoal (Admin)

  // Supporting accents
  static const Color skyBlue = Color(0xFF0EA5E9);

  // Gradients
  // Primary Healthcare Green Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [green, deepGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Doctor Clinical Gradient (Deep Green to Dark Clinical Green)
  static const LinearGradient doctorGradient = LinearGradient(
    colors: [deepGreen, darkClinicalGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // AI Assistant Premium Pink Gradient (Replaces purple AI gradient)
  static const LinearGradient aiGradient = LinearGradient(
    colors: [premiumPink, deepPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft Pink Tint Gradient (For AI cards, suggestion areas)
  static const LinearGradient softPinkGradient = LinearGradient(
    colors: [lightestPink, softPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Mint Tint Gradient (For Emergency QR cards)
  static const LinearGradient mintGradient = LinearGradient(
    colors: [veryLightMint, softMint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [green, deepGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
