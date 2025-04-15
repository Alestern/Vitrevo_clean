import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ocr_service.dart';
import '../services/openai_service.dart';
import '../utils/file_util.dart';
import 'analysis_result_page.dart';

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
  final OCRService _ocrService = OCRService();
  final OpenAIService _openAIService = OpenAIService();
  bool _isAnalyzing = true;
  bool _isNavigating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('[DEBUG] AnalysisLoadingPage initialized');
    // Start analysis after UI rendering is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  Future<void> _startAnalysis() async {
    try {
      setState(() {
        _isAnalyzing = true;
        _errorMessage = null;
      });
      
      print('[DEBUG] Starting OCR for both products');

      // Step 1: Perform OCR on both product images
      final String product1Text = await _ocrService.recognizeText(widget.imageFile1);
      print('[DEBUG] Product 1 OCR completed: ${product1Text.substring(0, product1Text.length > 50 ? 50 : product1Text.length)}...');
      
      final String product2Text = await _ocrService.recognizeText(widget.imageFile2);
      print('[DEBUG] Product 2 OCR completed: ${product2Text.substring(0, product2Text.length > 50 ? 50 : product2Text.length)}...');

      if (!mounted) return;

      // Step 2: Call OpenAI API with both product texts
      print('[DEBUG] Sending product comparison request to OpenAI');
      final analysis = await _openAIService.analyzeProducts(product1Text, product2Text);
      print('[DEBUG] Received analysis from OpenAI: Length ${analysis.length} chars');
      
      // Step 3: Validate the response
      if (analysis.startsWith('Error:')) {
        throw Exception(analysis);
      }
      
      if (analysis.length < 20) {
        throw Exception('Invalid analysis result: Response too short (${analysis.length} chars)');
      }

      if (!mounted) return;
      
      // Step 4: Navigate to results page
      _navigateToResultsPage(analysis, product1Text, product2Text);
      
    } catch (e) {
      print('[ERROR] Analysis error: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Analysis failed: $e';
      });
      
      // Show error dialog with retry option
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to analyze products: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Return to home page
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startAnalysis(); // Retry analysis
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToResultsPage(String analysis, String product1Text, String product2Text) {
    if (_isNavigating || !mounted) return;
    
    _isNavigating = true;
    print('[DEBUG] Navigating to results page');
    
    // Use safe navigation pattern for iOS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => AnalysisResultPage(
              imageFile1: widget.imageFile1,
              imageFile2: widget.imageFile2,
              productName1: widget.productName1,
              productName2: widget.productName2,
              analysisResult: analysis,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        
        // Cleanup temporary files after navigation
        FileUtil.cleanupTemporaryFiles([
          widget.imageFile1,
          widget.imageFile2,
        ]);
      });
    });
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
                  _isAnalyzing ? 'Analyzing products...' : 'Processing results...',
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startAnalysis,
                    child: const Text('Retry'),
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