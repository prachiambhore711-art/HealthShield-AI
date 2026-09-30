import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../auth/presentation/screens/app_lock_screen.dart';
import '../../presentation/screens/medical_profile_screen.dart';
import '../../presentation/screens/emergency_qr_screen.dart';
import '../../presentation/screens/emergency_access_screen.dart';
import '../../presentation/screens/patient_profile_screen.dart';
import '../widgets/dashboard_home_body.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLockShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AppLockService.lockSession();
    } else if (state == AppLifecycleState.resumed) {
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    if (_isLockShowing) return;
    final enabled = await AppLockService.isLockEnabled();
    if (enabled && !AppLockService.isUnlockedThisSession) {
      _isLockShowing = true;
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => AppLockScreen(
            onUnlocked: () {
              Navigator.pop(ctx, true);
            },
          ),
        ),
      );
      _isLockShowing = false;
    }
  }

  // Screens corresponding to bottom navigation tabs
  final List<Widget> _screens = [
    const DashboardHomeBody(),
    const MedicalProfileScreen(isNavigatedFromNavBar: true),
    const EmergencyQrScreen(isNavigatedFromNavBar: true),
    const EmergencyAccessScreen(isNavigatedFromNavBar: true),
    const PatientProfileScreen(isNavigatedFromNavBar: true),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          debugPrint("[NAV_DEBUG] Back button pressed on tab $_currentIndex -> returning to Home tab (0)");
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.white,
            selectedItemColor: AppColors.green,
            unselectedItemColor: AppColors.textGrey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded, color: AppColors.green),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment_rounded, color: AppColors.green),
                label: 'Records',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_outlined),
                activeIcon: Icon(Icons.qr_code_rounded, color: AppColors.green),
                label: 'QR Code',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.share_outlined),
                activeIcon: Icon(Icons.share_rounded, color: AppColors.green),
                label: 'Share',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person_rounded, color: AppColors.green),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
