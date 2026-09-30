import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_service.dart';

class DoctorService {
  String get baseUrl => AuthService.baseUrl;

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        if (AuthService.token != null) "Authorization": "Bearer ${AuthService.token}",
      };

  /// Get doctor profile details
  Future<Map<String, dynamic>> getDoctorProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/doctor/profile"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "profile": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to fetch profile."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Update doctor professional profile details
  Future<Map<String, dynamic>> updateDoctorProfile({
    required String professionalId,
    required String specialization,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/doctor/profile"),
        headers: headers,
        body: jsonEncode({
          "professional_id": professionalId,
          "specialization": specialization,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "profile": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to update profile."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Query verification status
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/doctor/verification-status"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Cache locally in AuthService too
        AuthService.doctorVerificationStatus = decoded["doctor_verification_status"];
        return {"success": true, "status": decoded["doctor_verification_status"]};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to verify status."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Request emergency access session by scanning opaque QR token
  Future<Map<String, dynamic>> requestEmergencyAccess(String qrToken) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/doctor/emergency-access/request"),
        headers: headers,
        body: jsonEncode({"token": qrToken}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "access_id": decoded["access_id"],
          "expires_at": decoded["expires_at"],
          "message": decoded["message"]
        };
      } else {
        return {
          "success": false,
          "message": decoded["detail"] ?? "Emergency access request failed."
        };
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Fetch active patient access sessions
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/doctor/emergency-access/active"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List decodedList = jsonDecode(response.body);
        return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Retrieve patient profile info under authorized session
  Future<Map<String, dynamic>> getAuthorizedPatientData(int accessId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/doctor/emergency-access/$accessId/patient"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "data": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to retrieve patient medical profile."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Download patient medical report file bytes
  Future<List<int>?> downloadReportFile(int accessId, int reportId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/doctor/emergency-access/$accessId/reports/$reportId/file"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  /// Revoke/terminate access session on doctor-side
  Future<Map<String, dynamic>> revokeEmergencyAccess(int accessId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/doctor/emergency-access/$accessId/revoke"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": decoded["message"]};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to revoke access."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Fetch previous access sessions log
  Future<List<Map<String, dynamic>>> getAccessHistory() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/doctor/emergency-access/history"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List decodedList = jsonDecode(response.body);
        return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }
}
