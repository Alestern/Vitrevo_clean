import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

class OCRService {
  final _textRecognizer = TextRecognizer();

  Future<String> recognizeText(File imageFile) async {
    try {
      debugPrint('Starting OCR for image: ${imageFile.path}');
      
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final text = _cleanText(recognizedText.text);
      debugPrint('OCR Result: $text');

      // Check if text quality is sufficient
      if (!_isTextQualitySufficient(text)) {
        throw Exception('Image quality is insufficient. Please take a clearer photo.');
      }
      
      return text;
    } catch (e) {
      debugPrint('OCR Error: $e');
      rethrow;
    }
  }

  bool _isTextQualitySufficient(String text) {
    // Check if text contains common nutritional terms
    final nutritionalTerms = [
      'calories', 'kcal', 'protein', 'fat', 'sugar', 'carbohydrate',
      'ingredients', 'nutrition', 'serving', 'per 100g', 'energia', 'energía',
      'protein', 'fibre', 'fibra', 'salt', 'sodium', 'grassi', 'zuccheri',
      'nutriti', 'valori', 'valores', 'nutricion', 'dichiarazione', 'acidi', 
      'carboidrati', 'proteine', 'sale', 'porzione', 'average', 'moyennes', 
      'durchschnitt', 'saturés', 'saturados', 'saturated'
    ];

    // Check for garbage text patterns
    final garbagePatterns = [
      'phalu tnigve', 'aaaa', 'eeee', 'xxxx', '??????',
      RegExp(r'([a-z])\1{5,}'), // Repeated characters (more than 5)
      RegExp(r'[^a-zA-Z0-9\s,.:]') // Non-alphanumeric patterns
    ];

    final lowercaseText = text.toLowerCase();
    
    // Check if any garbage patterns exist
    for (var pattern in garbagePatterns) {
      if (pattern is RegExp) {
        if (pattern.hasMatch(lowercaseText)) {
          print('OCR found garbage pattern: ${pattern.pattern}');
          return false;
        }
      } else if (lowercaseText.contains(pattern.toString())) {
        print('OCR found garbage text: $pattern');
        return false;
      }
    }
    
    // Check for sufficient nutritional content
    final matches = nutritionalTerms.where((term) => lowercaseText.contains(term)).length;
    
    // Consider text sufficient if it contains at least 2 nutritional terms and has reasonable length
    final hasMinimumTerms = matches >= 2;
    final hasReasonableLength = text.length > 50;
    
    if (!hasMinimumTerms) {
      print('OCR text has insufficient nutritional terms: $matches found, minimum 2 needed');
    }
    
    if (!hasReasonableLength) {
      print('OCR text is too short: ${text.length} chars, minimum 50 needed');
    }
    
    return hasMinimumTerms && hasReasonableLength;
  }

  String _cleanText(String text) {
    // Normalize spaces but preserve line breaks
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r' *\n *'), '\n')
        .trim();
  }

  // Extract nutritional facts from OCR text
  Map<String, double> extractNutritionalValues(String text) {
    final result = <String, double>{
      'calories': 0,
      'sugar': 0,
      'fat': 0,
      'saturatedFat': 0,
      'protein': 0,
      'fiber': 0
    };
    
    try {
      final normalizedText = text.replaceAll(',', '.').toLowerCase();
      
      // Calorie patterns - look for per 100g section
      final caloriePatterns = [
        // Look for common calorie patterns near "100g" or in nutrition declaration
        RegExp(r'(?:100\s*g|100g).*?(\d+\.?\d*)\s*kcal', caseSensitive: false),
        RegExp(r'energia.*?(\d+\.?\d*)\s*kcal', caseSensitive: false),
        RegExp(r'energy.*?(\d+\.?\d*)\s*kcal', caseSensitive: false),
        RegExp(r'calories.*?(\d+\.?\d*)\s*kcal', caseSensitive: false),
        RegExp(r'valore.*?(\d+\.?\d*)\s*kcal', caseSensitive: false),
        RegExp(r'valor.*?(\d+\.?\d*)\s*kcal', caseSensitive: false),
        RegExp(r'kj\s*\/\s*(\d+\.?\d*)\s*kcal', caseSensitive: false),
        // Last resort pattern - try to find any kcal value
        RegExp(r'(\d{3,4})(?:\.\d+)?\s*kcal', caseSensitive: false),
      ];
      
      // Sugar patterns - look specifically near 100g or nutritional values
      final sugarPatterns = [
        RegExp(r'(?:zuccher|sugar|sucre|azúcar).*?(\d+\.?\d*)\s*g', caseSensitive: false),
        RegExp(r'(?:100\s*g|100g).*?(?:zuccher|sugar|sucre|azúcar).*?(\d+\.?\d*)\s*g', caseSensitive: false),
        // Pattern for "of which sugars" common format
        RegExp(r'(?:di cui zuccher|of which sugar|dont sucre|de los cuales azúcar).*?(\d+\.?\d*)\s*g', caseSensitive: false),
      ];
      
      // Fat patterns
      final fatPatterns = [
        RegExp(r'(?:100\s*g|100g).*?(?:grass|fat|grais|gras).*?(\d+\.?\d*)\s*g', caseSensitive: false),
        RegExp(r'(?:grass|fat|grais|gras).*?(\d+\.?\d*)\s*g', caseSensitive: false),
      ];
      
      // Saturated fat patterns
      final saturatedFatPatterns = [
        RegExp(r'(?:saturat|sättig|saturi).*?(\d+\.?\d*)\s*g', caseSensitive: false),
        RegExp(r'(?:acidi grassi saturi|saturated fat|acides gras saturés).*?(\d+\.?\d*)\s*g', caseSensitive: false),
      ];
      
      // Protein patterns
      final proteinPatterns = [
        RegExp(r'(?:100\s*g|100g).*?(?:protein|protéin|protein).*?(\d+\.?\d*)\s*g', caseSensitive: false),
        RegExp(r'(?:protein|protéin|protein).*?(\d+\.?\d*)\s*g', caseSensitive: false),
      ];
      
      // Fiber patterns
      final fiberPatterns = [
        RegExp(r'(?:100\s*g|100g).*?(?:fib|fibr).*?(\d+\.?\d*)\s*g', caseSensitive: false),
        RegExp(r'(?:fib|fibr).*?(\d+\.?\d*)\s*g', caseSensitive: false),
        RegExp(r'(?:ballast|dietary fib).*?(\d+\.?\d*)\s*g', caseSensitive: false),
      ];
      
      // Try to find the per 100g section to focus our search
      // This improves accuracy by avoiding serving size values
      String per100gSection = normalizedText;
      final per100gPattern = RegExp(r'(?:per|su|pour|je|auf|por)\s*100\s*g.*', caseSensitive: false);
      final per100gMatch = per100gPattern.firstMatch(normalizedText);
      if (per100gMatch != null) {
        per100gSection = per100gMatch.group(0) ?? normalizedText;
        debugPrint('Found per 100g section: ${per100gSection.substring(0, min(50, per100gSection.length))}...');
      }
      
      // Extract values primarily from per 100g section if found
      _extractValue(result, 'calories', caloriePatterns, per100gSection);
      _extractValue(result, 'sugar', sugarPatterns, per100gSection);
      _extractValue(result, 'fat', fatPatterns, per100gSection);
      _extractValue(result, 'saturatedFat', saturatedFatPatterns, per100gSection);
      _extractValue(result, 'protein', proteinPatterns, per100gSection);
      _extractValue(result, 'fiber', fiberPatterns, per100gSection);
      
      // If we couldn't find values in the per 100g section, try the full text
      if (result['calories'] == 0) _extractValue(result, 'calories', caloriePatterns, normalizedText);
      if (result['sugar'] == 0) _extractValue(result, 'sugar', sugarPatterns, normalizedText);
      if (result['fat'] == 0) _extractValue(result, 'fat', fatPatterns, normalizedText);
      if (result['saturatedFat'] == 0) _extractValue(result, 'saturatedFat', saturatedFatPatterns, normalizedText);
      if (result['protein'] == 0) _extractValue(result, 'protein', proteinPatterns, normalizedText);
      if (result['fiber'] == 0) _extractValue(result, 'fiber', fiberPatterns, normalizedText);
      
      debugPrint('Extracted nutritional values: $result');
      
      // Validate the extracted values
      _validateNutritionalValues(result);
    } catch (e) {
      debugPrint('Error extracting nutritional values: $e');
    }
    
    return result;
  }
  
  // Helper method to extract value using patterns
  void _extractValue(Map<String, double> result, String key, List<RegExp> patterns, String text) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          double value = double.parse(match.group(1) ?? '0');
          // Basic sanity check for values
          if (_isReasonableValue(key, value)) {
            result[key] = value;
            debugPrint('Found $key: $value');
            break;
          } else {
            debugPrint('Unreasonable $key value found: $value - ignoring');
          }
        } catch (e) {
          debugPrint('Error parsing $key value: $e');
        }
      }
    }
  }
  
  // Check if a nutritional value is within reasonable bounds
  bool _isReasonableValue(String nutrient, double value) {
    switch (nutrient) {
      case 'calories':
        return value > 1 && value < 1000; // kcal per 100g
      case 'sugar':
        return value >= 0 && value < 100; // g per 100g
      case 'fat':
        return value >= 0 && value < 100; // g per 100g
      case 'saturatedFat':
        return value >= 0 && value < 100; // g per 100g
      case 'protein':
        return value >= 0 && value < 100; // g per 100g
      case 'fiber':
        return value >= 0 && value < 100; // g per 100g
      default:
        return true;
    }
  }
  
  // Basic validation of nutritional values for consistency
  void _validateNutritionalValues(Map<String, double> values) {
    // If we have fat and saturatedFat, make sure saturatedFat isn't greater than total fat
    if (values['fat']! > 0 && values['saturatedFat']! > values['fat']!) {
      debugPrint('Warning: Saturated fat (${values['saturatedFat']}) greater than total fat (${values['fat']}) - correcting');
      values['saturatedFat'] = values['fat']!;
    }
    
    // Make sure the sum of macronutrients doesn't exceed 100g per 100g
    double totalMacros = values['fat']! + values['protein']! + values['sugar']!;
    if (totalMacros > 100) {
      debugPrint('Warning: Total macronutrients ($totalMacros) exceeds 100g - values may be incorrect');
    }
    
    // Calculate expected calories based on macronutrients
    // Fat: 9 kcal/g, Protein: 4 kcal/g, Sugar: 4 kcal/g
    double expectedCalories = values['fat']! * 9 + values['protein']! * 4 + values['sugar']! * 4;
    
    // If we have reasonable macronutrient data but calories don't match, consider recalculating
    if (totalMacros > 10 && values['calories']! > 0) {
      double calorieDiscrepancy = (values['calories']! - expectedCalories).abs();
      if (calorieDiscrepancy > 200 && calorieDiscrepancy / values['calories']! > 0.5) {
        debugPrint('Warning: Calculated calories ($expectedCalories) differ significantly from extracted calories (${values['calories']})');
      }
    }
  }
  
  int min(int a, int b) {
    return a < b ? a : b;
  }
  
  // Extract product brand name from OCR text
  String extractProductBrand(String text) {
    try {
      // Common brand name patterns
      final brandPatterns = [
        RegExp(r'\b(Galbusera|Balocco|Colussi|Barilla|Mulino Bianco|Pavesi|Loacker|Coop|Migros|Carrefour|Aldi|Lidl|Misura|Kellogg|Nestlé|Danone|Muller|Sammontana|Motta|Algida|Ferrero|Plasmon|Mellin)\b', caseSensitive: false),
      ];
      
      for (final pattern in brandPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final brand = match.group(1) ?? '';
          debugPrint('Extracted brand: $brand');
          return brand.toLowerCase() == brand ? brand.capitalize() : brand;
        }
      }
      
      // Look for common product identifier patterns
      final productPatterns = [
        RegExp(r'prodotto da\s+([A-Z][A-Za-z\s]+)(?:\s+S\.p\.A\.|\s+S\.r\.l\.)?', caseSensitive: true),
        RegExp(r'distribuito da\s+([A-Z][A-Za-z\s]+)(?:\s+S\.p\.A\.|\s+S\.r\.l\.)?', caseSensitive: true),
        RegExp(r'produced by\s+([A-Z][A-Za-z\s]+)(?:\s+Ltd\.|\s+Inc\.)?', caseSensitive: true),
      ];
      
      for (final pattern in productPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final brand = match.group(1)?.trim() ?? '';
          if (brand.length > 2 && brand.length < 30) {
            debugPrint('Extracted brand from product info: $brand');
            return brand;
          }
        }
      }
    } catch (e) {
      debugPrint('Error extracting brand: $e');
    }
    
    return '';
  }

  Future<Map<String, dynamic>> recognizeMultipleImages(dynamic imageFiles) async {
    final results = <String, dynamic>{
      'text': '',
      'nutritionalValues': <String, double>{},
      'brand': ''
    };
    
    try {
      List<File> files = [];
      
      // Handle both single File and List<File> cases
      if (imageFiles is List<File>) {
        files = imageFiles;
      } else if (imageFiles is File) {
        files = [imageFiles];
      } else {
        throw Exception('Invalid image file type provided');
      }
      
      if (files.isEmpty) {
        throw Exception('No image files provided');
      }
      
      // Accumulate text from all images
      String combinedText = '';
      Map<String, double> nutritionalValues = {};
      String brand = '';
      
      for (var i = 0; i < files.length; i++) {
        final imageFile = files[i];
      final text = await recognizeText(imageFile);
        combinedText += '$text\n';
        
        // Extract values from each image
        final extractedValues = extractNutritionalValues(text);
        final extractedBrand = extractProductBrand(text);
        
        // Keep non-zero values from the current image
        extractedValues.forEach((key, value) {
          if (value > 0 && (nutritionalValues[key] == null || nutritionalValues[key] == 0)) {
            nutritionalValues[key] = value;
          }
        });
        
        // Keep the first valid brand found
        if (brand.isEmpty && extractedBrand.isNotEmpty) {
          brand = extractedBrand;
        }
      }
      
      // Set the results
      results['text'] = combinedText.trim();
      results['nutritionalValues'] = nutritionalValues;
      results['brand'] = brand;
    } catch (e) {
      debugPrint('Error in recognizeMultipleImages: $e');
      // Keep the default empty values but don't rethrow, let the analysis handle missing data
    }
    
    return results;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 