import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/forgot_password_screen.dart';
import 'features/auth/presentation/screens/patient_login_screen.dart';
import 'features/auth/presentation/screens/doctor_login_screen.dart';
import 'features/auth/presentation/screens/patient_register_screen.dart';
import 'features/auth/presentation/screens/doctor_register_screen.dart';
import 'features/auth/presentation/screens/onboarding_screens.dart';
import 'features/auth/presentation/screens/otp_verification_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/role_selection_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/admin_login_screen.dart';
import 'features/auth/data/auth_service.dart';

// Doctor Module Screens
import 'features/doctor/presentation/screens/doctor_dashboard_screen.dart';
import 'features/doctor/presentation/screens/doctor_verification_status_screen.dart';

// Patient Module Screens
import 'features/patient/presentation/screens/patient_dashboard_screen.dart';
import 'features/patient/presentation/screens/medical_profile_screen.dart';
import 'features/patient/presentation/screens/medical_reports_screen.dart';
import 'features/patient/presentation/screens/add_medical_report_screen.dart';
import 'features/patient/presentation/screens/emergency_contacts_screen.dart';
import 'features/patient/presentation/screens/add_edit_emergency_contact_screen.dart';
import 'features/patient/presentation/screens/patient_profile_screen.dart';
import 'features/patient/presentation/screens/settings_screen.dart';
import 'features/patient/presentation/screens/emergency_qr_screen.dart';
import 'features/patient/presentation/screens/emergency_access_screen.dart';
import 'features/patient/presentation/screens/ai_assistant_screen.dart';
import 'features/patient/presentation/screens/reminders_screen.dart';
import 'core/services/notification_service.dart';
import 'features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'features/admin/presentation/screens/admin_doctor_requests_screen.dart';
import 'features/admin/presentation/screens/admin_doctor_details_screen.dart';
import 'features/admin/presentation/screens/admin_user_management_screen.dart';
import 'features/admin/presentation/screens/admin_audit_logs_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await AuthService.init();
  runApp(const HealthShieldApp());
}

class HealthShieldApp extends StatelessWidget {
  const HealthShieldApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'HealthShield AI',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreens(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/patient-login': (context) => const PatientLoginScreen(),
        '/doctor-login': (context) => const DoctorLoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/patient-register': (context) => const PatientRegisterScreen(),
        '/doctor-register': (context) => const DoctorRegisterScreen(),
        // Fallbacks mapping to patient pages for backward compatibility
        '/login': (context) => const PatientLoginScreen(),
        '/register': (context) => const PatientRegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/verify-otp': (context) => const OtpVerificationScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        
        // Admin Module Screen Routes
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/admin/doctor-requests': (context) => const AdminDoctorRequestsScreen(),
        '/admin/doctor-details': (context) => const AdminDoctorDetailsScreen(),
        '/admin/users': (context) => const AdminUserManagementScreen(),
        '/admin/audit-logs': (context) => const AdminAuditLogsScreen(),
        
        // Doctor Module Screen Routes
        '/doctor/dashboard': (context) {
          if (AuthService.userRole == "admin") {
            return const AdminDashboardScreen();
          }
          return const DoctorDashboardScreen();
        },
        '/doctor/verification-status': (context) => const DoctorVerificationStatusScreen(),

        // Patient Module Screen Routes
        '/patient/dashboard': (context) {
          if (AuthService.userRole == "admin") {
            return const AdminDashboardScreen();
          }
          return const PatientDashboardScreen();
        },
        '/patient/medical-profile': (context) => const MedicalProfileScreen(),
        '/patient/reports': (context) => const MedicalReportsScreen(),
        '/patient/add-report': (context) => const AddMedicalReportScreen(),
        '/patient/contacts': (context) => const EmergencyContactsScreen(),
        '/patient/add-edit-contact': (context) => const AddEditEmergencyContactScreen(),
        '/patient/profile': (context) => const PatientProfileScreen(),
        '/patient/settings': (context) => const SettingsScreen(),
        '/patient/qr': (context) => const EmergencyQrScreen(),
        '/patient/access': (context) => const EmergencyAccessScreen(),
        '/patient/ai-assistant': (context) => const AIAssistantScreen(),
        '/patient/reminders': (context) => const RemindersScreen(),
      },
    );
  }
}
