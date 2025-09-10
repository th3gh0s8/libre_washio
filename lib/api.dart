import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // --- Updated Base URL ---
  // For Android Emulator (PHP server running on localhost:8000 on your machine)
  static const String baseUrl = "http://10.0.2.2:8000/";
  // For iOS Simulator or web:
  // static const String baseUrl = "http://localhost:8000/";
  // For Physical Device (replace YOUR_COMPUTER_IP with your actual IP address):
  // static const String baseUrl = "http://YOUR_COMPUTER_IP:8000/";
  // --- --- 

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

  static Future<List<Map<String, dynamic>>> getUserVehicles(int userId) async {
    // Assuming your PHP script is get_user_vehicles.php
    final url = Uri.parse('${baseUrl}get_user_vehicles.php?user_id=$userId'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (decodedResponse['status'] == 'success') {
          if (decodedResponse['data'] != null) {
            final List<dynamic> vehicleDataList = decodedResponse['data'] as List<dynamic>;
            return vehicleDataList.map((vehicleData) => vehicleData as Map<String, dynamic>).toList();
          } else {
            return []; 
          }
        } else {
          throw Exception('Failed to load vehicles: ${decodedResponse['message']}');
        }
      } else {
        throw Exception('Failed to load vehicles. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  static Future<Map<String, dynamic>> addVehicle({
    required int userId,
    required String vehicleNo,
    required String vehicleType,
    required String vehicleModel,
  }) async {
    final url = Uri.parse('${baseUrl}add_vehicle.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'user_id': userId.toString(),
          'vehicle_no': vehicleNo,
          'vehicle_type': vehicleType,
          'vehicle_model': vehicleModel,
        },
      );
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse;
      } else {
        throw Exception('Failed to add vehicle. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding vehicle: $e');
    }
  }

  static Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required int userId, 
    required String vehicleNo,
    required String vehicleType,
    required String vehicleModel,
  }) async {
    final url = Uri.parse('${baseUrl}update_vehicle.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'vehicle_id': vehicleId.toString(),
          'user_id': userId.toString(),
          'vehicle_no': vehicleNo,
          'vehicle_type': vehicleType,
          'vehicle_model': vehicleModel,
        },
      );
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse; 
      } else {
        throw Exception('Failed to update vehicle. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating vehicle: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteVehicle({
    required int vehicleId,
    required int userId, 
  }) async {
    final url = Uri.parse('${baseUrl}delete_vehicle.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'vehicle_id': vehicleId.toString(),
          'user_id': userId.toString(),
        },
      );
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse;
      } else {
        throw Exception('Failed to delete vehicle. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting vehicle: $e');
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
        // The decodedResponse will contain 'status', 'message', 
        // and now also 'otp_purpose' and 'otp_for_testing' if successful.
        return decodedResponse;
      } else {
        throw Exception('Failed to request OTP. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error requesting OTP: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(String countryCode, String localPhoneNumber, String otp, String otpPurpose) async {
    final url = Uri.parse('${baseUrl}verify_otp.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'country_code': countryCode,
          'local_phone_number': localPhoneNumber,
          'otp': otp,
          'otp_purpose': otpPurpose, // This parameter is used by verify_otp.php
        },
      );
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse;
      } else {
        throw Exception('Failed to verify OTP. Status code: ${response.statusCode}, Body: ${response.body}');
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
    String? address, 
    String? vehicleNo,
    String? vehicleType,
    String? vehicleModel,
  }) async {
    final url = Uri.parse('${baseUrl}register_user.php');
    
    Map<String, String> body = {
      'name': name,
      'email': email,
      'phone': phone,
      'country_code': countryCode,
    };

    if (address != null && address.isNotEmpty) {
      body['address'] = address;
    }

    if (vehicleNo != null && vehicleNo.isNotEmpty &&
        vehicleType != null && vehicleType.isNotEmpty &&
        vehicleModel != null && vehicleModel.isNotEmpty) {
      body['vehicle_no'] = vehicleNo;
      body['vehicle_type'] = vehicleType;
      body['vehicle_model'] = vehicleModel;
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse;
      } else {
        throw Exception('Failed to register user. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error registering user: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUserDetails({
    required int userId,
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
          'user_id': userId.toString(),
          'name': name,
          'email': email,
          if (address != null) 'address': address,
        },
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse;
      } else {
        throw Exception('Failed to update user details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user details: $e');
    }
  }
}