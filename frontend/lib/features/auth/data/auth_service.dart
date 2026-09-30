import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/services/notification_service.dart';

class AuthService {
  static String? _customBaseUrl;

  /// Initialize AuthService and load saved server URL from persistent storage
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('api_base_url');
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _customBaseUrl = savedUrl.trim();
        debugPrint("[AUTH_DEBUG] Loaded custom baseUrl from storage: $_customBaseUrl");
      }
    } catch (e) {
      debugPrint("[AUTH_DEBUG] Error reading api_base_url from storage: $e");
    }
  }

  /// Update the server base URL and persist it across app restarts
  static Future<void> setBaseUrl(String newUrl) async {
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'http://$cleanUrl';
    }
    _customBaseUrl = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_base_url', cleanUrl);
      debugPrint("[AUTH_DEBUG] Persisted new baseUrl: $cleanUrl");
    } catch (e) {
      debugPrint("[AUTH_DEBUG] Error saving api_base_url to storage: $e");
    }
  }

  /// Reset to default base URL
  static Future<void> resetBaseUrl() async {
    _customBaseUrl = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_base_url');
      debugPrint("[AUTH_DEBUG] Cleared custom baseUrl from storage");
    } catch (_) {}
  }

  /// Check server connectivity by pinging /docs
  static Future<bool> testConnection([String? testUrl]) async {
    final url = testUrl ?? baseUrl;
    try {
      final response = await http.get(Uri.parse("$url/docs")).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("[AUTH_DEBUG] testConnection to $url failed: $e");
      return false;
    }
  }

  // Configured at build/run time using --dart-define or runtime settings dialog.
  static String get baseUrl {
    // 1. Manually set custom URL has top priority
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    // 2. Build-time defined URL (--dart-define=API_BASE_URL=...)
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    if (definedUrl.isNotEmpty) {
      return definedUrl;
    }
    // 3. Desktop and Web development default to localhost
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://127.0.0.1:8000';
    }
    // 4. Android physical device fallback to active development machine Wi-Fi LAN IP
    return 'http://192.168.1.4:8000';
  }

  /// Async helper for base URL
  static Future<String> getBaseUrl() async => baseUrl;

  // In-memory session cache
  static String? token;
  static String? userRole;
  static String? userFullName;
  static String? doctorVerificationStatus;
  static String? cachedEmailOrPhone; // Helpful to carry from register/forgot-password to OTP screen

  static Map<String, String> get _headers => {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };

  /// Helper to safely extract error message from String, List, or Map detail
  static String _extractErrorMessage(dynamic detail, {String defaultMessage = "Authentication failed."}) {
    if (detail == null) return defaultMessage;
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first.containsKey("msg")) {
        return first["msg"].toString();
      }
      return detail.map((e) {
        if (e is Map && e.containsKey("msg")) return e["msg"];
        return e.toString();
      }).join(", ");
    }
    if (detail is Map) {
      if (detail.containsKey("msg")) return detail["msg"].toString();
      if (detail.containsKey("message")) return detail["message"].toString();
      if (detail.containsKey("detail")) return _extractErrorMessage(detail["detail"]);
    }
    return detail.toString();
  }

  /// Register a new account (Patient or Doctor)
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
    String? specialization,
    String? professionalId,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "full_name": fullName,
        "email": email,
        "phone_number": phoneNumber,
        "password": password,
        "role": role,
      };
      if (specialization != null && specialization.trim().isNotEmpty) {
        requestBody["specialization"] = specialization.trim();
      }
      if (professionalId != null && professionalId.trim().isNotEmpty) {
        requestBody["professional_id"] = professionalId.trim();
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/register"),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      final decodedBody = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        cachedEmailOrPhone = email;
        return {"success": true, "data": decodedBody};
      } else {
        return {
          "success": false,
          "message": _extractErrorMessage(decodedBody?["detail"], defaultMessage: "Failed to register account.")
        };
      }
    } on TimeoutException {
      return {"success": false, "message": "Connection timed out. Please check your network connection."};
    } on SocketException {
      return {"success": false, "message": "Unable to connect to the server at $baseUrl. Please verify the server is running."};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Verify OTP to activate account or approve password resets
  Future<Map<String, dynamic>> verifyOtp({
    required String emailOrPhone,
    required String code,
    required String purpose,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/verify-otp"),
        headers: _headers,
        body: jsonEncode({
          "email_or_phone": emailOrPhone,
          "code": code,
          "purpose": purpose,
        }),
      ).timeout(const Duration(seconds: 15));

      final decodedBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": decodedBody};
      } else {
        return {
          "success": false,
          "message": _extractErrorMessage(decodedBody?["detail"], defaultMessage: "Invalid OTP code.")
        };
      }
    } on TimeoutException {
      return {"success": false, "message": "Connection timed out. Please try again."};
    } on SocketException {
      return {"success": false, "message": "Unable to connect to the server at $baseUrl."};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Login user with isolated notification, timeout, and distinct error reporting
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
    String? role,
  }) async {
    debugPrint("[AUTH_DEBUG] login() called for: $emailOrPhone (role: $role) at $baseUrl");
    try {
      final uri = Uri.parse("$baseUrl/api/auth/login");
      debugPrint("[AUTH_DEBUG] Sending POST request to: $uri");

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          "email_or_phone": emailOrPhone,
          "password": password,
          if (role != null) "role": role,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint("[AUTH_DEBUG] Request to $uri timed out after 15 seconds");
          throw TimeoutException("Connection timed out connecting to $baseUrl. The server took too long to respond.");
        },
      );

      debugPrint("[AUTH_DEBUG] HTTP ${response.statusCode}: ${response.body}");

      dynamic decodedBody;
      try {
        decodedBody = jsonDecode(response.body);
      } catch (e) {
        debugPrint("[AUTH_DEBUG] JSON decode error: $e");
        return {
          "success": false,
          "message": "Invalid response received from server (${response.statusCode}).",
        };
      }

      if (response.statusCode == 200) {
        token = decodedBody["access_token"];
        userRole = decodedBody["role"];
        userFullName = decodedBody["full_name"];
        doctorVerificationStatus = decodedBody["doctor_verification_status"];

        // Secondary client validation guard: verify backend returned the requested role
        if (role != null && userRole != null && userRole!.toLowerCase() != role.toLowerCase()) {
          debugPrint("[ROLE_DEBUG] Role mismatch detected on client: expected $role, received $userRole");
          logout();
          return {
            "success": false,
            "message": "Access restricted to $role role only.",
          };
        }

        // Safely persist session without letting storage errors fail login
        try {
          final prefs = await SharedPreferences.getInstance();
          if (token != null) await prefs.setString("jwt_token", token!);
          if (userRole != null) await prefs.setString("user_role", userRole!);
          if (userFullName != null) await prefs.setString("user_full_name", userFullName!);
          if (doctorVerificationStatus != null) {
            await prefs.setString("doctor_verification_status", doctorVerificationStatus!);
          } else {
            await prefs.remove("doctor_verification_status");
          }
          debugPrint("[AUTH_DEBUG] Session stored in SharedPreferences");
        } catch (storageError) {
          debugPrint("[AUTH_DEBUG] SharedPreferences persistence warning (non-fatal): $storageError");
        }

        // Defensive notification call for patient - failure must NEVER fail authentication
        if (userRole == "patient") {
          try {
            await NotificationService.showEmergencyNotification();
            debugPrint("[AUTH_DEBUG] Emergency notification shown");
          } catch (notifError) {
            debugPrint("[AUTH_DEBUG] Notification display warning (non-fatal): $notifError");
          }
        }

        return {"success": true, "data": decodedBody};
      } else if (response.statusCode == 401) {
        final message = _extractErrorMessage(
          decodedBody?["detail"],
          defaultMessage: "Incorrect credentials. Please try again.",
        );
        return {"success": false, "message": message};
      } else if (response.statusCode == 403) {
        final message = _extractErrorMessage(
          decodedBody?["detail"],
          defaultMessage: "Access forbidden.",
        );
        return {"success": false, "message": message};
      } else if (response.statusCode == 422) {
        final message = _extractErrorMessage(
          decodedBody?["detail"],
          defaultMessage: "Validation error. Please check your email and password format.",
        );
        return {"success": false, "message": message};
      } else {
        final message = _extractErrorMessage(
          decodedBody?["detail"],
          defaultMessage: "Server returned error (${response.statusCode}).",
        );
        return {"success": false, "message": message};
      }
    } on TimeoutException catch (e) {
      debugPrint("[AUTH_DEBUG] TimeoutException caught: $e");
      return {
        "success": false,
        "message": e.message ?? "Connection timed out. The server took too long to respond.",
      };
    } on SocketException catch (e) {
      debugPrint("[AUTH_DEBUG] SocketException caught: $e");
      return {
        "success": false,
        "message": "Unable to connect to server at $baseUrl. Please verify the backend is running and your device is on the same network.",
      };
    } on http.ClientException catch (e) {
      debugPrint("[AUTH_DEBUG] ClientException caught: $e");
      return {
        "success": false,
        "message": "Network connection error: ${e.message}",
      };
    } catch (e, stackTrace) {
      debugPrint("[AUTH_DEBUG] Unexpected exception in login(): $e\n$stackTrace");
      return {
        "success": false,
        "message": "An unexpected error occurred: $e",
      };
    }
  }

  /// Trigger forgot password code email/phone dispatch
  Future<Map<String, dynamic>> forgotPassword(String emailOrPhone) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/forgot-password"),
        headers: _headers,
        body: jsonEncode({"email_or_phone": emailOrPhone}),
      ).timeout(const Duration(seconds: 15));

      final decodedBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        cachedEmailOrPhone = emailOrPhone;
        return {"success": true, "message": decodedBody["message"]};
      } else {
        return {
          "success": false,
          "message": _extractErrorMessage(decodedBody?["detail"], defaultMessage: "Failed to request password reset.")
        };
      }
    } on TimeoutException {
      return {"success": false, "message": "Connection timed out. Please try again."};
    } on SocketException {
      return {"success": false, "message": "Unable to connect to the server at $baseUrl."};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Reset user credentials
  Future<Map<String, dynamic>> resetPassword({
    required String emailOrPhone,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/reset-password"),
        headers: _headers,
        body: jsonEncode({
          "email_or_phone": emailOrPhone,
          "code": code,
          "new_password": newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      final decodedBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": decodedBody["message"]};
      } else {
        return {
          "success": false,
          "message": _extractErrorMessage(decodedBody?["detail"], defaultMessage: "Failed to reset password.")
        };
      }
    } on TimeoutException {
      return {"success": false, "message": "Connection timed out. Please try again."};
    } on SocketException {
      return {"success": false, "message": "Unable to connect to the server at $baseUrl."};
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Logout and flush current credentials
  static void logout() {
    token = null;
    userRole = null;
    userFullName = null;
    doctorVerificationStatus = null;
    cachedEmailOrPhone = null;

    NotificationService.clearNotification();

    SharedPreferences.getInstance().then((prefs) {
      prefs.remove("jwt_token");
      prefs.remove("user_role");
      prefs.remove("user_full_name");
      prefs.remove("doctor_verification_status");
    });
  }

  /// Locally checks if the stored JWT is expired
  static bool isTokenExpired(String jwtToken) {
    try {
      final parts = jwtToken.split('.');
      if (parts.length != 3) return true;
      
      String payload = parts[1];
      payload = base64.normalize(payload);
      final String decoded = utf8.decode(base64.decode(payload));
      final Map<String, dynamic> claims = jsonDecode(decoded);
      
      if (claims.containsKey('exp')) {
        final int exp = claims['exp'];
        final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        return now >= exp;
      }
    } catch (_) {
      return true;
    }
    return false;
  }

  /// Restore authentication session from SharedPreferences
  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString("jwt_token");
      final savedRole = prefs.getString("user_role");
      
      if (savedToken != null && savedRole != null) {
        if (isTokenExpired(savedToken)) {
          await prefs.remove("jwt_token");
          await prefs.remove("user_role");
          await prefs.remove("user_full_name");
          await prefs.remove("doctor_verification_status");
          return false;
        }
        token = savedToken;
        userRole = savedRole;
        userFullName = prefs.getString("user_full_name") ?? "";
        doctorVerificationStatus = prefs.getString("doctor_verification_status");

        if (userRole == "patient") {
          NotificationService.showEmergencyNotification();
        }

        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Get active or persisted authentication token
  static Future<String?> getSavedToken() async {
    if (token != null && token!.isNotEmpty) return token;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("jwt_token");
    } catch (_) {
      return null;
    }
  }
}
