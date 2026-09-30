import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_service.dart';

class ReminderService {
  Future<String> _getBaseUrl() async {
    return await AuthService.getBaseUrl();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getSavedToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token ?? ''}",
    };
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/patient/reminders'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> data) async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/patient/reminders'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {"success": false, "message": err["detail"] ?? "Failed to create reminder"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection timeout or server error: $e"};
    }
  }

  Future<Map<String, dynamic>> updateReminder(int id, Map<String, dynamic> data) async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/patient/reminders/$id'),
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        final err = jsonDecode(response.body);
        return {"success": false, "message": err["detail"] ?? "Failed to update reminder"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> toggleReminder(int id) async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/patient/reminders/$id/toggle'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "message": "Failed to toggle reminder status"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> deleteReminder(int id) async {
    try {
      final baseUrl = await _getBaseUrl();
      final response = await http
          .delete(
            Uri.parse('$baseUrl/api/patient/reminders/$id'),
            headers: await _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {"success": true, "message": "Reminder deleted"};
      } else {
        return {"success": false, "message": "Failed to delete reminder"};
      }
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }
}
