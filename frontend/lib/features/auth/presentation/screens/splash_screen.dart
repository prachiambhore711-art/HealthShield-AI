import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_background.dart';
import 'package:frontend/core/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Fade-in animation for branding elements
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    final hasSession = await AuthService.restoreSession();
    
    // Maintain splash duration for at least 3 seconds for branding
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    if (hasSession) {
      final role = AuthService.userRole;
      if (role == "patient") {
        if (NotificationService.pendingRoute == '/patient/qr') {
          NotificationService.pendingRoute = null;
          Navigator.pushReplacementNamed(context, '/patient/dashboard');
          Navigator.pushNamed(context, '/patient/qr');
        } else {
          Navigator.pushReplacementNamed(context, '/patient/dashboard');
        }
      } else if (role == "doctor") {
        Navigator.pushReplacementNamed(context, '/doctor/dashboard');
      } else if (role == "admin") {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // Logo Card
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback medical icon if logo not loaded
                          return const Icon(
                            Icons.shield,
                            size: 80,
                            color: AppColors.green,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // App Title
                Text(
                  "HealthShield AI",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.textDark,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Text(
                  "Your Health, Your Shield",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textGrey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(flex: 2),
                // Caring statement
                Text(
                  "Caring for you, always.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.deepGreen.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 32),
                // Progress Indicator
                const SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white,
                    color: AppColors.green,
                    minHeight: 4,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
