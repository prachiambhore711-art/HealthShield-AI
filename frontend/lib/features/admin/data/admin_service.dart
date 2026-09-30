import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../features/auth/data/auth_service.dart';

class AdminService {
  String get baseUrl => AuthService.baseUrl;

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        if (AuthService.token != null) "Authorization": "Bearer ${AuthService.token}",
      };

  /// Fetch all pending doctor verification requests
  Future<List<Map<String, dynamic>>> getPendingDoctors() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/admin/doctors/pending"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Get specific doctor details
  Future<Map<String, dynamic>> getDoctorDetails(int doctorId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/admin/doctors/$doctorId"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "doctor": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to load details."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Verify doctor
  Future<Map<String, dynamic>> verifyDoctor(int doctorId, String notes) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/admin/doctors/$doctorId/verify"),
        headers: headers,
        body: jsonEncode({"notes": notes}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "doctor": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Verification failed."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Reject doctor
  Future<Map<String, dynamic>> rejectDoctor(int doctorId, String notes) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/admin/doctors/$doctorId/reject"),
        headers: headers,
        body: jsonEncode({"notes": notes}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "doctor": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Rejection failed."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Suspend doctor
  Future<Map<String, dynamic>> suspendDoctor(int doctorId, String notes) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/admin/doctors/$doctorId/suspend"),
        headers: headers,
        body: jsonEncode({"notes": notes}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "doctor": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Suspension failed."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Reactivate doctor
  Future<Map<String, dynamic>> reactivateDoctor(int doctorId, String notes) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/admin/doctors/$doctorId/reactivate"),
        headers: headers,
        body: jsonEncode({"notes": notes}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "doctor": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Reactivation failed."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  /// Search system users (patients, doctors, admins)
  Future<List<Map<String, dynamic>>> searchUsers({String? query, String? role}) async {
    try {
      final queryParams = <String>[];
      if (query != null && query.isNotEmpty) {
        queryParams.add("query=${Uri.encodeComponent(query)}");
      }
      if (role != null && role.isNotEmpty) {
        queryParams.add("role=${Uri.encodeComponent(role)}");
      }
      final queryString = queryParams.isNotEmpty ? "?${queryParams.join('&')}" : "";
      
      final response = await http.get(
        Uri.parse("$baseUrl/api/admin/users/search$queryString"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Retrieve administrative verification log history
  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/admin/audit-logs"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }
}
