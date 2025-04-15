import 'dart:io';
import 'package:flutter/material.dart';
import '../services/mlkit_ocr_service.dart';
import '../services/openai_service.dart';
import '../utils/file_util.dart';
import 'analysis_result_page.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:math';

class AnalysisLoadingPage extends StatefulWidget {
  final File imageFile1;
  final File imageFile2;
  final String productName1;
  final String productName2;

  const AnalysisLoadingPage({
    Key? key,
    required this.imageFile1,
    required this.imageFile2,
    required this.productName1,
    required this.productName2,
  }) : super(key: key);

  @override
  State<AnalysisLoadingPage> createState() => _AnalysisLoadingPageState();
}

class _AnalysisLoadingPageState extends State<AnalysisLoadingPage> {
  final MLKitOCRService _ocrService = MLKitOCRService();
  final OpenAIService _openAIService = OpenAIService();
  bool _isLoading = true;
  bool _isNavigating = false;
  String? _errorMessage;
  String? _product1Text;
  String? _product2Text;

  @override
  void initState() {
    super.initState();
    debugPrint('[DEBUG] AnalysisLoadingPage initialized');
    // Start analysis after UI rendering is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  void _startAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Perform OCR on both images using ML Kit
      debugPrint('Starting OCR analysis for product 1...');
      _product1Text = await _ocrService.recognizeText(widget.imageFile1);
      
      // Check if OCR text is valid
      if (_product1Text == null || _product1Text!.isEmpty || _product1Text!.length < 20) {
        throw Exception('Could not extract sufficient text from product 1. Please take a clearer photo.');
      }
      
      debugPrint('OCR Product 1 Text (${_product1Text!.length} chars): ${_product1Text!.substring(0, min(100, _product1Text!.length))}...');
      
      debugPrint('Starting OCR analysis for product 2...');
      _product2Text = await _ocrService.recognizeText(widget.imageFile2);
      
      // Check if OCR text is valid
      if (_product2Text == null || _product2Text!.isEmpty || _product2Text!.length < 20) {
        throw Exception('Could not extract sufficient text from product 2. Please take a clearer photo.');
      }
      
      debugPrint('OCR Product 2 Text (${_product2Text!.length} chars): ${_product2Text!.substring(0, min(100, _product2Text!.length))}...');

      // Send product comparison request to OpenAI
      debugPrint('Sending comparison request to OpenAI...');
      String analysis = await _openAIService.analyzeProducts(
        _product1Text!, 
        _product2Text!,
      );
      
      debugPrint('Received analysis (${analysis.length} chars)');
      
      // Verify if the analysis has a valid format with a clear recommendation
      bool isValidAnalysis = analysis.isNotEmpty && 
                          (analysis.toUpperCase().contains('RECOMMENDATION: PRODUCT A') || 
                           analysis.toUpperCase().contains('RECOMMENDATION: PRODUCT B') ||
                           analysis.contains('I recommend Product A') ||
                           analysis.contains('I recommend Product B'));
      
      if (!isValidAnalysis) {
        debugPrint('Invalid analysis format - does not contain a clear recommendation');
        
        // Try to extract some key terms to ensure we got nutrition-related content
        bool containsNutritionTerms = analysis.toLowerCase().contains('sugar') || 
                                    analysis.toLowerCase().contains('protein') ||
                                    analysis.toLowerCase().contains('fat') ||
                                    analysis.toLowerCase().contains('calories');
        
        if (!containsNutritionTerms) {
          throw Exception('Invalid analysis: Missing nutritional comparison');
        }
        
        // If it has nutrition terms but no recommendation, we'll proceed and let the result page
        // determine the recommendation based on nutritional values
        debugPrint('Analysis contains nutrition terms but no explicit recommendation - will determine from data');
      }

      setState(() {
        _isLoading = false;
      });

      _navigateToResultsPage(analysis);
    } catch (e) {
      debugPrint('Error during analysis: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      _showErrorDialog();
    }
  }

  void _navigateToResultsPage(String analysisResult) {
    if (!mounted) return;
    
    debugPrint('[DEBUG] Navigating to results page with analysis (${analysisResult.length} chars)');
    
    // Extract basic nutritional information from OCR text
    final Map<String, dynamic> nutritionalValues1 = _extractBasicNutritionalInfo(_product1Text ?? '');
    final Map<String, dynamic> nutritionalValues2 = _extractBasicNutritionalInfo(_product2Text ?? '');
    
    // Create properly typed maps for product data
    // Fix: Using explicit type definitions to ensure consistency
    final List<Map<String, dynamic>> typedProductsData = [
      <String, dynamic>{
        'nutritionalValues': nutritionalValues1,
        'brand': _extractBrand(_product1Text ?? ''),
      },
      <String, dynamic>{
        'nutritionalValues': nutritionalValues2,
        'brand': _extractBrand(_product2Text ?? ''),
      },
    ];
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisResultPage(
          imageFiles: [widget.imageFile1, widget.imageFile2],
          productNames: [widget.productName1, widget.productName2],
          analysisResult: analysisResult,
          productsData: typedProductsData,
        ),
      ),
    );
  }
  
  // Simple method to extract basic nutritional values from OCR text
  Map<String, dynamic> _extractBasicNutritionalInfo(String text) {
    final result = <String, dynamic>{};
    
    // Extract calories
    final calorieMatch = RegExp(r'(\d+\.?\d*)\s*kcal').firstMatch(text.toLowerCase());
    if (calorieMatch != null && calorieMatch.group(1) != null) {
      try {
        result['calories'] = double.parse(calorieMatch.group(1)!);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    // Extract sugar
    final sugarMatch = RegExp(r'(?:sugar|zuccheri?|sucre).*?(\d+\.?\d*)\s*g').firstMatch(text.toLowerCase());
    if (sugarMatch != null && sugarMatch.group(1) != null) {
      try {
        result['sugar'] = double.parse(sugarMatch.group(1)!);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    // Extract fat
    final fatMatch = RegExp(r'(?:fat|grassi|grais).*?(\d+\.?\d*)\s*g').firstMatch(text.toLowerCase());
    if (fatMatch != null && fatMatch.group(1) != null) {
      try {
        result['fat'] = double.parse(fatMatch.group(1)!);
      } catch (e) {
        // Ignore parsing errors
      }
    }
    
    debugPrint('Extracted nutritional values: $result');
    return result;
  }
  
  // Simple method to extract brand from OCR text
  String _extractBrand(String text) {
    final brands = [
      'Galbusera', 'Balocco', 'Barilla', 'Mulino Bianco', 'Pavesi', 'Loacker',
      'Colussi', 'Misura', 'Plasmon', 'Kellogg', 'Nestlé'
    ];
    
    for (final brand in brands) {
      if (text.contains(brand)) {
        return brand;
      }
    }
    
    return 'Unknown';
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analysis Error'),
        content: Text(_errorMessage!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Ensure we don't intercept back navigation while navigating
        if (_isNavigating) return false;
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analyzing Products'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 24),
                Text(
                  _isLoading ? 'Analyzing products...' : 'Processing results...',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comparing nutritional information and ingredients',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _startAnalysis,
                    child: const Text('Retry Analysis'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
} 