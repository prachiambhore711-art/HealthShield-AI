import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/custom_button.dart';

class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({Key? key}) : super(key: key);

  @override
  State<OnboardingScreens> createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Your Health. Your Data.\nYour Control.",
      description: "Keep your essential health information secure and accessible when it matters most.",
      accentColor: AppColors.green,
      circleBgColor: AppColors.veryLightMint,
      imageAsset: "assets/images/illustrations/onboarding_patient.png",
    ),
    OnboardingPageData(
      title: "One Secure QR for\nEmergency Access",
      description: "Give authorized healthcare professionals fast access to the information they need during an emergency.",
      accentColor: AppColors.deepGreen,
      circleBgColor: AppColors.softMint,
      imageAsset: "assets/images/illustrations/onboarding_doctor_qr.png",
    ),
    OnboardingPageData(
      title: "Intelligent Health\nAssistance Anytime",
      description: "Get health education, helpful guidance, and personalized wellness insights whenever you need them.",
      accentColor: AppColors.premiumPink,
      circleBgColor: AppColors.softPink,
      imageAsset: "assets/images/illustrations/onboarding_ai_assistant.png",
    ),
  ];

  void _onNextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushNamed(context, '/role-selection');
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
          leadingWidth: 180,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.shield_rounded,
                          size: 20,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "HealthShield AI",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (_currentIndex < _pages.length - 1)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/role-selection');
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Large Hero Soft-3D Illustration
                          Expanded(
                            child: Center(
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 280, maxWidth: 280),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: page.accentColor.withOpacity(0.08),
                                      blurRadius: 32,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    page.imageAsset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: page.circleBgColor,
                                      child: Icon(Icons.health_and_safety_rounded, size: 80, color: page.accentColor),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppColors.textDark,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                          ),
                          const SizedBox(height: 10),
                          // Supporting Text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textGrey,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Layout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  children: [
                    // Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          height: 6,
                          width: _currentIndex == index ? 24 : 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? _pages[_currentIndex].accentColor
                                : AppColors.borderGrey,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary Full-Width Action Button
                    CustomButton(
                      text: _currentIndex == _pages.length - 1 ? "Get Started" : "Next",
                      gradient: _currentIndex == 2
                          ? AppColors.aiGradient // Premium Pink for AI
                          : AppColors.primaryGradient,
                      onPressed: _onNextPage,
                    ),
                    const SizedBox(height: 14),

                    // Trust Badge Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.green),
                        const SizedBox(width: 6),
                        Text(
                          "Your health data is safe with us",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textGrey,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String description;
  final Color accentColor;
  final Color circleBgColor;
  final String imageAsset;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.accentColor,
    required this.circleBgColor,
    required this.imageAsset,
  });
}
