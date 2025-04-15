import 'package:flutter/material.dart';
import 'dart:io';

class AnalysisResultPage extends StatefulWidget {
  final File imageFile1;
  final File imageFile2;
  final String productName1;
  final String productName2;
  final String analysisResult;

  const AnalysisResultPage({
    Key? key,
    required this.imageFile1,
    required this.imageFile2,
    required this.productName1,
    required this.productName2,
    required this.analysisResult,
  }) : super(key: key);

  @override
  State<AnalysisResultPage> createState() => _AnalysisResultPageState();
}

class _AnalysisResultPageState extends State<AnalysisResultPage> {
  bool _isNavigating = false;
  
  @override
  void initState() {
    super.initState();
    print('[DEBUG] AnalysisResultPage initialized');
  }
  
  bool _isProduct1Recommended() {
    final lowerResult = widget.analysisResult.toLowerCase();
    return lowerResult.contains('product a is recommended') || 
           lowerResult.contains('first product is recommended') ||
           lowerResult.contains('product a is healthier') ||
           lowerResult.contains('the first product is healthier') ||
           lowerResult.contains('recommend product a') ||
           lowerResult.contains('${widget.productName1.toLowerCase()} is recommended');
  }
  
  void _returnToHome() {
    if (_isNavigating) return;
    
    _isNavigating = true;
    print('[DEBUG] Return to home triggered');
    
    // Use the safe navigation pattern for iOS
    FocusManager.instance.primaryFocus?.unfocus();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        
        print('[DEBUG] Navigating back to home');
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    });
  }

  Color _getRecommendationColor() {
    final lowerResult = widget.analysisResult.toLowerCase();
    if (lowerResult.contains('product a is') || 
        lowerResult.contains('product 1 is') ||
        lowerResult.contains('first product is') ||
        lowerResult.contains('${widget.productName1.toLowerCase()} is')) {
      return Colors.green;
    } else if (lowerResult.contains('product b is') ||
               lowerResult.contains('product 2 is') ||
               lowerResult.contains('second product is') ||
               lowerResult.contains('${widget.productName2.toLowerCase()} is')) {
      return Colors.green;
    }
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    final bool isProduct1Recommended = _isProduct1Recommended();
    
    return WillPopScope(
      onWillPop: () async {
        if (_isNavigating) return false;
        _returnToHome();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analysis Results'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _returnToHome,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductComparison(isProduct1Recommended),
              const SizedBox(height: 24),
              _buildRecommendationExplanation(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isNavigating ? null : _returnToHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Return to Home', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductComparison(bool isProduct1Recommended) {
    return Column(
      children: [
        _buildProductCard(
          widget.imageFile1,
          isProduct1Recommended,
          widget.productName1,
        ),
        const SizedBox(height: 16),
        _buildProductCard(
          widget.imageFile2,
          !isProduct1Recommended,
          widget.productName2,
        ),
      ],
    );
  }

  Widget _buildProductCard(File image, bool isRecommended, String title) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRecommended ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.file(
                  image,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (isRecommended)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationExplanation() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getRecommendationColor(),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: _getRecommendationColor()),
                const SizedBox(width: 8),
                const Text(
                  'AI Recommendation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.check_circle, color: _getRecommendationColor()),
              ],
            ),
            const Divider(height: 24),
            
            // Structured content display
            Text(
              widget.analysisResult,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
} 