// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stockdata.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000'; // Your Flask backend URL

  Future<AnalysisResult> analyzeStock(String symbol) async {
    final response = await http.get(Uri.parse('$baseUrl/analyze?symbol=$symbol'));

    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to analyze stock: ${response.body}');
    }
  }
}