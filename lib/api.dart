import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //static const String baseUrl = "http://washio_api.dvl.to/";
  static const String baseUrl = "http://192.168.1.10/washio_api/"; // Correct IP and base path

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
          'phone': phoneNumber,
          'country_code': countryCode,
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

  static Future<Map<String, dynamic>> verifyOtp(String fullPhoneNumber, String otp) async {
    final url = Uri.parse('${baseUrl}verify_otp.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'full_phone_number': fullPhoneNumber,
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
    required String phone,
    required String countryCode,
    String? address, // Optional
  }) async {
    final url = Uri.parse('${baseUrl}register_user.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'name': name,
          'email': email,
          'phone': phone, // Local part of the phone number
          'country_code': countryCode,
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse; // Expected keys: status, message, user_id (on success)
      } else {
        throw Exception('Failed to register user. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }
}