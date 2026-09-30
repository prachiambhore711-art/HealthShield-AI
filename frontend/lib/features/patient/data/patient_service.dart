import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_service.dart';

class PatientService {
  String get baseUrl => AuthService.baseUrl;

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        if (AuthService.token != null) "Authorization": "Bearer ${AuthService.token}",
      };

  // ----------------------------------------------------
  // 1. MEDICAL PROFILE SERVICES
  // ----------------------------------------------------

  Future<Map<String, dynamic>> getMedicalProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/patient/profile"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "profile": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to fetch medical profile."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> updateMedicalProfile(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/patient/profile"),
        headers: headers,
        body: jsonEncode(data),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "profile": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to update medical profile."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // ----------------------------------------------------
  // 2. EMERGENCY CONTACT SERVICES
  // ----------------------------------------------------

  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/patient/contacts"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List decodedList = jsonDecode(response.body);
        return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> addEmergencyContact({
    required String name,
    required String relationship,
    required String phoneNumber,
    required bool isPrimary,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/patient/contacts"),
        headers: headers,
        body: jsonEncode({
          "name": name,
          "relationship": relationship,
          "phone_number": phoneNumber,
          "is_primary": isPrimary,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "contact": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to add emergency contact."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> updateEmergencyContact({
    required int id,
    required String name,
    required String relationship,
    required String phoneNumber,
    required bool isPrimary,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/api/patient/contacts/$id"),
        headers: headers,
        body: jsonEncode({
          "name": name,
          "relationship": relationship,
          "phone_number": phoneNumber,
          "is_primary": isPrimary,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "contact": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to update emergency contact."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteEmergencyContact(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/patient/contacts/$id"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": decoded["message"] ?? "Deleted successfully"};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to delete contact."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // ----------------------------------------------------
  // 3. MEDICAL REPORT SERVICES
  // ----------------------------------------------------

  Future<List<Map<String, dynamic>>> getMedicalReports() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/patient/reports"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List decodedList = jsonDecode(response.body);
        return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> uploadMedicalReport({
    required String title,
    required String type,
    required String date,
    String? description,
    required String filePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/api/patient/reports"),
      );

      if (AuthService.token != null) {
        request.headers['Authorization'] = 'Bearer ${AuthService.token}';
      }

      request.fields['title'] = title;
      request.fields['type'] = type;
      request.fields['report_date'] = date;
      if (description != null) {
        request.fields['description'] = description;
      }

      // Read file and add to multipart
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "report": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to upload medical report."};
      }
    } catch (e) {
      return {"success": false, "message": "File upload error: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteMedicalReport(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/api/patient/reports/$id"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": decoded["message"] ?? "Deleted successfully"};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to delete report."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // ----------------------------------------------------
  // 4. EMERGENCY QR SERVICES
  // ----------------------------------------------------

  Future<Map<String, dynamic>> getEmergencyQr() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/patient/qr"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "qr": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to load Emergency QR."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> regenerateEmergencyQr() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/patient/qr/regenerate"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "qr": decoded};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to regenerate QR."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  // ----------------------------------------------------
  // 5. EMERGENCY ACCESS SERVICES
  // ----------------------------------------------------

  Future<List<Map<String, dynamic>>> getActiveEmergencyAccess() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/patient/emergency-access/active"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List decodedList = jsonDecode(response.body);
        return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> revokeEmergencyAccess(int accessId) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/patient/emergency-access/revoke/$accessId"),
        headers: headers,
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "message": decoded["message"] ?? "Access revoked."};
      } else {
        return {"success": false, "message": decoded["detail"] ?? "Failed to revoke access."};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<List<Map<String, dynamic>>> getEmergencyAccessHistory() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/patient/emergency-access/history"),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List decodedList = jsonDecode(response.body);
        return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getNearbyProviders(double lat, double lng, {double radiusKm = 50.0}) async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/api/patient/nearby-providers?latitude=$lat&longitude=$lng&radius_km=$radiusKm"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List decodedList = jsonDecode(response.body);
        final list = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
        return {
          "success": true,
          "providers": list,
          "statusCode": 200,
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return {
          "success": false,
          "providers": <Map<String, dynamic>>[],
          "statusCode": response.statusCode,
          "error": "Authentication session expired. Please re-login.",
        };
      } else {
        return {
          "success": false,
          "providers": <Map<String, dynamic>>[],
          "statusCode": response.statusCode,
          "error": "Server error (${response.statusCode}) retrieving providers.",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "providers": <Map<String, dynamic>>[],
        "statusCode": 0,
        "error": "Connection error: Unable to reach healthcare provider server.",
      };
    }
  }

  // ----------------------------------------------------
  // 6. AI CHAT SERVICE
  // ----------------------------------------------------

  Future<Map<String, dynamic>> sendAIChat(String query) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/api/patient/ai-chat"),
            headers: headers,
            body: jsonEncode({"query": query}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {"success": true, "response": decoded["response"]};
      }
      return {"success": false};
    } catch (e) {
      return {"success": false, "message": "$e"};
    }
  }
}
