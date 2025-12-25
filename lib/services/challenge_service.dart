import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/challenge_model.dart';

class ChallengeService {
  static const String baseUrl = 'https://subintentional-corinne-componental.ngrok-free.dev/api';

  // Get all active challenges
  Future<List<Challenge>> getActiveChallenges() async {
    try {
      print('Fetching challenges from: $baseUrl/challenges?filter=active');

      final response = await http.get(
        Uri.parse('$baseUrl/challenges?filter=active'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // Handle both array and object responses
        final List<dynamic> data = responseData is List
            ? responseData
            : (responseData['data'] ?? responseData['challenges'] ?? []);

        print('Successfully parsed ${data.length} challenges');
        return data.map((json) => Challenge.fromJson(json)).toList();
      } else {
        print('Failed to load challenges: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      print('Error fetching challenges: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get challenges by frequency
  Future<List<Challenge>> getChallengesByFrequency(String frequency) async {
    try {
      final challenges = await getActiveChallenges();
      return challenges.where((c) => c.frequency == frequency).toList();
    } catch (e) {
      print('Error fetching challenges by frequency: $e');
      return [];
    }
  }

  // Get challenge by ID
  Future<Challenge?> getChallengeById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/challenges/$id'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Challenge.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching challenge: $e');
      return null;
    }
  }

  // Test connection
  Future<bool> testConnection() async {
    try {
      print('Testing connection to: $baseUrl/challenges');
      final response = await http.get(
        Uri.parse('$baseUrl/challenges'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      print('Connection test status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}