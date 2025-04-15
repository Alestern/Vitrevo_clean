import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

class MLKitOCRService {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeText(File imageFile) async {
    try {
      debugPrint('Starting MLKit OCR for image: ${imageFile.path}');
      
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      final text = _cleanText(recognizedText.text);
      debugPrint('MLKit OCR Result: $text');

      // Check if text quality is sufficient
      if (!_isTextQualitySufficient(text)) {
        throw Exception('Image quality is insufficient. Please take a clearer photo of the nutrition label.');
      }
      
      return text;
    } catch (e) {
      debugPrint('MLKit OCR Error: $e');
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

    final lowercaseText = text.toLowerCase();
    
    // Check for sufficient nutritional content
    final matches = nutritionalTerms.where((term) => lowercaseText.contains(term)).length;
    
    // Consider text sufficient if it contains at least 2 nutritional terms and has reasonable length
    final hasMinimumTerms = matches >= 2;
    final hasReasonableLength = text.length > 50;
    
    if (!hasMinimumTerms) {
      debugPrint('OCR text has insufficient nutritional terms: $matches found, minimum 2 needed');
    }
    
    if (!hasReasonableLength) {
      debugPrint('OCR text is too short: ${text.length} chars, minimum 50 needed');
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

  void dispose() {
    textRecognizer.close();
  }
} 