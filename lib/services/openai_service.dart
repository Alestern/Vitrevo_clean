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
  
  Future<String> analyzeProducts(
    String productTextA,
    String productTextB,
    {Map<String, dynamic>? productAData,
    Map<String, dynamic>? productBData}
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'Error: OpenAI API key not found';
    }

    if (productTextA.isEmpty || productTextB.isEmpty) {
      return 'Error: Product text is empty';
    }

    // Extract nutritional values from data if available
    String nutritionalInfoA = '';
    String nutritionalInfoB = '';
    
    if (productAData != null && productAData.containsKey('nutritionalValues')) {
      var nutrition = productAData['nutritionalValues'];
      nutritionalInfoA = '''
Calories: ${nutrition['calories'] ?? 'Not found'}
Sugar: ${nutrition['sugar'] ?? 'Not found'}
Fat: ${nutrition['fat'] ?? 'Not found'}
Saturated Fat: ${nutrition['saturatedFat'] ?? 'Not found'}
Protein: ${nutrition['protein'] ?? 'Not found'}
Fiber: ${nutrition['fiber'] ?? 'Not found'}
''';
    }
    
    if (productBData != null && productBData.containsKey('nutritionalValues')) {
      var nutrition = productBData['nutritionalValues'];
      nutritionalInfoB = '''
Calories: ${nutrition['calories'] ?? 'Not found'}
Sugar: ${nutrition['sugar'] ?? 'Not found'}
Fat: ${nutrition['fat'] ?? 'Not found'}
Saturated Fat: ${nutrition['saturatedFat'] ?? 'Not found'}
Protein: ${nutrition['protein'] ?? 'Not found'}
Fiber: ${nutrition['fiber'] ?? 'Not found'}
''';
    }
    
    // Extract brand info if available
    String brandA = productAData != null && productAData.containsKey('brand') 
        ? "Brand: ${productAData['brand']}\n" 
        : '';
    String brandB = productBData != null && productBData.containsKey('brand') 
        ? "Brand: ${productBData['brand']}\n" 
        : '';

    final prompt = '''
Compare these two product nutritional labels and recommend which is healthier.

Product A:
$brandA
$nutritionalInfoA
Full text from image:
$productTextA

Product B:
$brandB
$nutritionalInfoB
Full text from image:
$productTextB

Guidelines for analysis:
1. Start with a clear recommendation: "I recommend Product A" or "I recommend Product B"
2. Focus on sugar content as a primary factor - lower sugar is better
3. Consider saturated fat, total fat, fiber, and protein
4. Products with more protein and fiber are generally better
5. If both products have similar nutritional profiles, recommend the one with less sugar
6. If sugar is equal, recommend the one with less saturated fat
7. Always provide a clear explanation for your recommendation

Your response should be structured as follows:
RECOMMENDATION: [Product A or Product B]
REASONING: [Brief explanation focusing on key nutritional differences]
KEY DIFFERENCES: [List the main nutritional differences]
''';

    try {
      print('[DEBUG] Sending product comparison request to OpenAI API');
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'user',
              'content': prompt
            }
          ],
          'temperature': 0.3,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.statusCode == 200
            ? response.body
            : '{"error": "Failed to get response"}');

        if (data.containsKey('choices') && data['choices'].isNotEmpty) {
          String content = data['choices'][0]['message']['content'];
          
          // Validate the response before returning
          if (_validateGptResponse(content, productAData, productBData)) {
            return content;
          } else {
            return _fixResponseFormat(content);
          }
        } else {
          return 'Error: Invalid response format from API';
        }
      } else {
        print('[ERROR] API request failed: ${response.statusCode}');
        return 'Error: Failed to get a response (${response.statusCode})';
      }
    } catch (e) {
      print('[ERROR] Exception during OpenAI request: $e');
      return 'Error: $e';
    }
  }

  bool _validateGptResponse(String response, Map<String, dynamic>? productAData, Map<String, dynamic>? productBData) {
    // Check if the response starts with a clear recommendation
    if (!response.toUpperCase().contains('RECOMMENDATION:') && 
        !response.contains('I recommend Product A') && 
        !response.contains('I recommend Product B')) {
      print('[VALIDATION] Response missing clear recommendation format');
      return false;
    }

    // Extract which product is recommended
    bool isProductARecommended = response.contains('I recommend Product A') || 
                                 response.toUpperCase().contains('RECOMMENDATION: PRODUCT A');
    bool isProductBRecommended = response.contains('I recommend Product B') || 
                                 response.toUpperCase().contains('RECOMMENDATION: PRODUCT B');

    // Check if we have nutritional data to validate against
    if (productAData != null && 
        productBData != null && 
        productAData.containsKey('nutritionalValues') && 
        productBData.containsKey('nutritionalValues')) {
      
      // Fix: Ensure we have a Map<String, dynamic> by using Map.from
      var nutritionA = productAData['nutritionalValues'] is Map 
          ? Map<String, dynamic>.from(productAData['nutritionalValues']) 
          : <String, dynamic>{};
          
      var nutritionB = productBData['nutritionalValues'] is Map 
          ? Map<String, dynamic>.from(productBData['nutritionalValues']) 
          : <String, dynamic>{};
      
      // Get sugar values if available
      double? sugarA = nutritionA['sugar'] != null ? 
                      double.tryParse(nutritionA['sugar'].toString().replaceAll(RegExp(r'[^\d.]'), '')) : null;
      double? sugarB = nutritionB['sugar'] != null ? 
                      double.tryParse(nutritionB['sugar'].toString().replaceAll(RegExp(r'[^\d.]'), '')) : null;
      
      // Get saturated fat values if available
      double? satFatA = nutritionA['saturatedFat'] != null ? 
                       double.tryParse(nutritionA['saturatedFat'].toString().replaceAll(RegExp(r'[^\d.]'), '')) : null;
      double? satFatB = nutritionB['saturatedFat'] != null ? 
                       double.tryParse(nutritionB['saturatedFat'].toString().replaceAll(RegExp(r'[^\d.]'), '')) : null;
      
      // Basic validation: if sugar values are available for both products and the difference is significant
      if (sugarA != null && sugarB != null) {
        bool shouldPreferA = sugarA < sugarB;
        bool shouldPreferB = sugarB < sugarA;
        
        // If sugar is equal, check saturated fat
        if (sugarA == sugarB && satFatA != null && satFatB != null) {
          shouldPreferA = satFatA < satFatB;
          shouldPreferB = satFatB < satFatA;
        }
        
        // Check if recommendation matches our validation
        if ((shouldPreferA && !isProductARecommended && isProductBRecommended) ||
            (shouldPreferB && !isProductBRecommended && isProductARecommended)) {
          print('[VALIDATION] Recommendation conflicts with nutritional data');
          return false;
        }
      }
    }
    
    return true;
  }

  String _fixResponseFormat(String content) {
    // If the response doesn't have the expected format, try to fix it
    if (content.contains('recommend Product A') || 
        content.toLowerCase().contains('product a is healthier') ||
        content.toLowerCase().contains('product a is better')) {
      
      return '''RECOMMENDATION: Product A
REASONING: Based on the analysis of the nutritional information
KEY DIFFERENCES: The nutritional properties of Product A appear to be more favorable than Product B.
$content''';
    } 
    else if (content.contains('recommend Product B') || 
             content.toLowerCase().contains('product b is healthier') ||
             content.toLowerCase().contains('product b is better')) {
             
      return '''RECOMMENDATION: Product B
REASONING: Based on the analysis of the nutritional information
KEY DIFFERENCES: The nutritional properties of Product B appear to be more favorable than Product A.
$content''';
    }
    
    // If we can't determine a clear recommendation, return original content
    return content;
  }
} 