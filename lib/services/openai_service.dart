import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OpenAIService {
  static final String? _apiKey = dotenv.env['OPENAI_API_KEY'];
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const Duration _timeout = Duration(seconds: 15);

  Future<String> analyzeText(String text) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        print('[ERROR] OpenAI API key not found');
        return 'Error: API key is not configured';
      }

      if (text.isEmpty) {
        print('[ERROR] Empty text received');
        return 'Error: Insufficient product information. Please try again with clearer photos.';
      }

      print('[DEBUG] Sending request to OpenAI API');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that analyzes product information.'
            },
            {
              'role': 'user',
              'content': 'Analyze this product information: $text'
            }
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        }),
      ).timeout(_timeout);

      print('[DEBUG] OpenAI API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('choices') && 
            data['choices'] is List && 
            data['choices'].isNotEmpty &&
            data['choices'][0].containsKey('message') &&
            data['choices'][0]['message'].containsKey('content')) {
          
          final result = data['choices'][0]['message']['content'];
          print('[DEBUG] OpenAI response received');
          return result;
        } else {
          print('[ERROR] Invalid response format from OpenAI');
          return 'Error: Invalid response format from AI service';
        }
      } else {
        print('[ERROR] OpenAI API error: ${response.statusCode} - ${response.body}');
        
        if (response.statusCode == 401) {
          return 'Error: Authentication failed (401)';
        } else if (response.statusCode == 429) {
          return 'Error: Rate limit exceeded (429)';
        } else {
          return 'Error: Service error (${response.statusCode})';
        }
      }
    } on TimeoutException {
      print('[ERROR] OpenAI API request timed out');
      return 'Error: Request timed out';
    } catch (e) {
      print('[ERROR] Exception in OpenAI service: $e');
      return 'Error: $e';
    }
  }
  
  Future<String> analyzeProducts(String productAText, String productBText) async {
    try {
      if (_apiKey == null || _apiKey!.isEmpty) {
        print('[ERROR] OpenAI API key not found');
        return 'Error: API key is not configured';
      }

      if (productAText.isEmpty || productBText.isEmpty) {
        print('[ERROR] Empty product text received');
        return 'Error: Insufficient product information. Please try again with clearer photos.';
      }

      print('[DEBUG] Sending product comparison request to OpenAI API');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a nutrition expert that compares two products and provides a clear, concise analysis. Focus on nutritional benefits, ingredients quality, and health implications.'
            },
            {
              'role': 'user',
              'content': '''Compare these two products based on their nutritional information:
              
Product A:
$productAText

Product B:
$productBText

Provide a structured analysis with these sections:
1. Key Nutritional Differences
2. Ingredient Quality Comparison
3. Health Recommendation (which product is healthier and why)

Keep your analysis concise and evidence-based.'''
            }
          ],
          'temperature': 0.2,
          'max_tokens': 800,
        }),
      ).timeout(_timeout);

      print('[DEBUG] OpenAI API comparison response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('choices') && 
            data['choices'] is List && 
            data['choices'].isNotEmpty &&
            data['choices'][0].containsKey('message') &&
            data['choices'][0]['message'].containsKey('content')) {
          
          final result = data['choices'][0]['message']['content'];
          print('[DEBUG] OpenAI comparison response received');
          return result;
        } else {
          print('[ERROR] Invalid comparison response format from OpenAI');
          return 'Error: Invalid response format from AI service';
        }
      } else {
        print('[ERROR] OpenAI API comparison error: ${response.statusCode} - ${response.body}');
        
        if (response.statusCode == 401) {
          return 'Error: Authentication failed (401)';
        } else if (response.statusCode == 429) {
          return 'Error: Rate limit exceeded (429)';
        } else {
          return 'Error: Service error (${response.statusCode})';
        }
      }
    } on TimeoutException {
      print('[ERROR] OpenAI API comparison request timed out');
      return 'Error: Request timed out';
    } catch (e) {
      print('[ERROR] Exception in OpenAI comparison service: $e');
      return 'Error: $e';
    }
  }
} 