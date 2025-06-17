import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/temperature_data.dart';

class TemperatureService {
  static const String baseUrl = 'https://api.temphist.com'; // API URL
  static const String apiKey = 'testing'; // API key

  Future<TemperatureData> getTemperatureData(String location, String month, String date) async {
    final response = await http.get(
      Uri.parse('$baseUrl/data/$location/$month-$date'),
      headers: {
        'X-API-Token': apiKey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return TemperatureData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load temperature data: ${response.statusCode}');
    }
  }
} 