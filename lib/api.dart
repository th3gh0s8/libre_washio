import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //static const String baseUrl = "http://washio_api.dvl.to/";
  static const String baseUrl = "http://192.168.1.10/washio_api/"; // Ensure this IP is correct for your XAMPP server

  static Future<Map<String, dynamic>> getUserDetails(int userId) async {
    final url = Uri.parse('${baseUrl}get_user_details.php?userId=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (decodedResponse['status'] == 'success') {
          return decodedResponse['data'] as Map<String, dynamic>;
        } else {
          throw Exception('Failed to load user details: ${decodedResponse['message']}');
        }
      } else {
        throw Exception('Failed to load user details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user details: $e');
    }
  }

  static Future<Map<String, dynamic>> requestOtp(String phoneNumber, String countryCode) async {
    final url = Uri.parse('${baseUrl}request_otp.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'phone': phoneNumber, // This is the local phone number part
          'country_code': countryCode, // This is the country code like +94
        },
      );
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse;
      } else {
        throw Exception('Failed to request OTP. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error requesting OTP: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String countryCode, String localPhoneNumber, String otp) async {
    final url = Uri.parse('${baseUrl}verify_otp.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'country_code': countryCode,       // e.g., "+94"
          'local_phone_number': localPhoneNumber, // e.g., "771234567"
          'otp': otp,
        },
      );
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse;
      } else {
        throw Exception('Failed to verify OTP. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error verifying OTP: $e');
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String phone, // This is the local phone number part
    required String countryCode, // This is the country code like +94
    String? address, 
  }) async {
    final url = Uri.parse('${baseUrl}register_user.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'name': name,
          'email': email,
          'phone': phone, 
          'country_code': countryCode,
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse; 
      } else {
        throw Exception('Failed to register user. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUserDetails({
    required int userId, // PHP script expects user_id as int for SQL binding
    required String name,
    required String email,
    String? address,
  }) async {
    final url = Uri.parse('${baseUrl}update_user_details.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'user_id': userId.toString(), // Convert int to String for form body
          'name': name,
          'email': email,
          // Send address even if it's null or empty, PHP script handles it.
          // If address is null from Flutter, it won't be in the map.
          // If it's an empty string, it will be sent as such.
          if (address != null) 'address': address, 
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse; // Expected keys: status, message, user_data (on success)
      } else {
        throw Exception('Failed to update user details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user details: $e');
    }
  }
}