import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.100/washio_api';

  // Method to get the list of service stations
  static Future<List<Map<String, dynamic>>> getStations() async {
    final response = await http.get(Uri.parse('$baseUrl/get_stations.php'));

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        return List<Map<String, dynamic>>.from(responseBody['data']);
      } else {
        throw Exception('Failed to load stations: ${responseBody['message']}');
      }
    } else {
      throw Exception('Failed to connect to the server. Status code: ${response.statusCode}');
    }
  }

  // Method to get services for a specific station
  static Future<List<Map<String, dynamic>>> getServicesForStation(int stationId) async {
    final response = await http.get(Uri.parse('$baseUrl/get_services.php?station_id=$stationId'));

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody['status'] == 'success') {
        return List<Map<String, dynamic>>.from(responseBody['data']);
      } else {
        throw Exception('Failed to load services: ${responseBody['message']}');
      }
    } else {
      throw Exception('Failed to connect to the server. Status code: ${response.statusCode}');
    }
  }

  // Method to register a new user
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
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register_user.php'),
        body: {
          'name': name,
          'email': email,
          'phone': phone,
          'country_code': countryCode,
          if (address != null) 'address': address,
          if (vehicleNo != null) 'vehicle_no': vehicleNo,
          if (vehicleType != null) 'vehicle_type': vehicleType,
          if (vehicleModel != null) 'vehicle_model': vehicleModel,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Method to request an OTP
  static Future<Map<String, dynamic>> requestOtp(String phone, String countryCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/request_otp.php'),
      body: {
        'phone': phone,
        'country_code': countryCode,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to request OTP. Status: ${response.statusCode}');
    }
  }

  // Method to verify an OTP
  static Future<Map<String, dynamic>> verifyOtp(String phone, String countryCode, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify_otp.php'),
      body: {
        'phone': phone,
        'country_code': countryCode,
        'otp': otp,
      },
    );

    if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("API Response for verifyOtp: $data");
        return data;
    } else {
        debugPrint("Server error for verifyOtp: ${response.statusCode}");
        throw Exception('Failed to verify OTP. Status: ${response.statusCode}');
    }
  }

    // Method to get user details by ID
  static Future<Map<String, dynamic>> getUserDetails(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/get_user_details.php?user_id=$userId'));

    if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
            return data['data'];
        } else {
            throw Exception(data['message'] ?? 'Failed to get user details.');
        }
    } else {
        throw Exception('Failed to connect to get user details. Status: ${response.statusCode}');
    }
  }

  // Method to update user details
  static Future<Map<String, dynamic>> updateUserDetails({
    required int userId,
    required String name,
    required String email,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_user_details.php'),
        body: {
          'user_id': userId.toString(),
          'name': name,
          'email': email,
          if (address != null) 'address': address,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // --- RESTORED VEHICLE METHODS ---

  static Future<List<Map<String, dynamic>>> getUserVehicles(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/get_vehicles.php?user_id=$userId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['vehicles']);
      } else {
        throw Exception(data['message'] ?? 'Failed to get vehicles.');
      }
    } else {
      throw Exception('Failed to connect to server.');
    }
  }

  static Future<Map<String, dynamic>> addVehicle({
    required int userId,
    required String vehicleNo,
    required String vehicleType,
    required String vehicleModel,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_vehicle.php'),
      body: {
        'user_id': userId.toString(),
        'vehicle_no': vehicleNo,
        'vehicle_type': vehicleType,
        'vehicle_model': vehicleModel,
      },
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> updateVehicle({
    required int vehicleId,
    required String vehicleNo,
    required String vehicleType,
    required String vehicleModel,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update_vehicle.php'),
      body: {
        'vehicle_id': vehicleId.toString(),
        'vehicle_no': vehicleNo,
        'vehicle_type': vehicleType,
        'vehicle_model': vehicleModel,
      },
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> deleteVehicle(int vehicleId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete_vehicle.php'),
      body: {
        'vehicle_id': vehicleId.toString(),
      },
    );
    return json.decode(response.body);
  }
}
