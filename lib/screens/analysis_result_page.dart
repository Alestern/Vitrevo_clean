import 'dart:io';
import 'package:flutter/material.dart';

class AnalysisResultPage extends StatelessWidget {
  final List<File> imageFiles;
  final List<String> productNames;
  final String analysisResult;
  final List<Map<String, dynamic>> productsData;

  const AnalysisResultPage({
    Key? key,
    required this.imageFiles,
    required this.productNames,
    required this.analysisResult,
    required this.productsData,
  }) : super(key: key);

  bool isProductARecommended() {
    // First check for explicit recommendation in the analysis result
    if (analysisResult.toUpperCase().contains('RECOMMENDATION: PRODUCT A') ||
        analysisResult.contains('I recommend Product A') ||
        analysisResult.contains('Product A is recommended')) {
      return true;
    } else if (analysisResult.toUpperCase().contains('RECOMMENDATION: PRODUCT B') ||
               analysisResult.contains('I recommend Product B') ||
               analysisResult.contains('Product B is recommended')) {
      return false;
    }
    
    // If no explicit recommendation, compare nutritional values
    final nutritionalValuesA = productsData[0].containsKey('nutritionalValues') 
        ? Map<String, dynamic>.from(productsData[0]['nutritionalValues'] ?? {}) 
        : <String, dynamic>{};
    
    final nutritionalValuesB = productsData[1].containsKey('nutritionalValues') 
        ? Map<String, dynamic>.from(productsData[1]['nutritionalValues'] ?? {}) 
        : <String, dynamic>{};
    
    // Get sugar content (prioritize this)
    final double sugarA = nutritionalValuesA['sugar'] is num ? nutritionalValuesA['sugar'].toDouble() : 100.0;
    final double sugarB = nutritionalValuesB['sugar'] is num ? nutritionalValuesB['sugar'].toDouble() : 100.0;
    
    // If sugar content is significantly different, use that as the deciding factor
    if ((sugarA - sugarB).abs() > 0.5) {
      return sugarA < sugarB;
    }
    
    // If sugar is similar, check saturated fat
    final double satFatA = nutritionalValuesA['saturatedFat'] is num ? nutritionalValuesA['saturatedFat'].toDouble() : 100.0;
    final double satFatB = nutritionalValuesB['saturatedFat'] is num ? nutritionalValuesB['saturatedFat'].toDouble() : 100.0;
    
    if ((satFatA - satFatB).abs() > 0.5) {
      return satFatA < satFatB;
    }
    
    // If all else is similar, check protein (higher is better)
    final double proteinA = nutritionalValuesA['protein'] is num ? nutritionalValuesA['protein'].toDouble() : 0.0;
    final double proteinB = nutritionalValuesB['protein'] is num ? nutritionalValuesB['protein'].toDouble() : 0.0;
    
    if ((proteinA - proteinB).abs() > 0.5) {
      return proteinA > proteinB;
    }
    
    // Default to product A if we can't determine
    return true;
  }

  Color _getRecommendationColor(bool isRecommended) {
    return isRecommended ? Colors.green.shade800 : Colors.grey.shade700;
  }

  void _returnToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final bool productARecommended = isProductARecommended();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _returnToHome(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductComparison(context, productARecommended),
              const SizedBox(height: 24),
              const Text(
                'Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  analysisResult,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _returnToHome(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Compare New Products'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductComparison(BuildContext context, bool productARecommended) {
    return Row(
      children: [
        Expanded(
          child: _buildProductCard(
            context,
            'Product A',
            imageFiles[0],
            productARecommended,
            Map<String, dynamic>.from(productsData[0]['nutritionalValues'] ?? {}),
            productsData[0]['brand'] ?? 'Unknown',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildProductCard(
            context,
            'Product B',
            imageFiles[1],
            !productARecommended,
            Map<String, dynamic>.from(productsData[1]['nutritionalValues'] ?? {}),
            productsData[1]['brand'] ?? 'Unknown',
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    String title,
    File imageFile,
    bool isRecommended,
    Map<String, dynamic> nutritionalValues,
    String brand,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _getRecommendationColor(isRecommended),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and recommendation status
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getRecommendationColor(isRecommended),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isRecommended)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.recommend, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Recommended',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Product image
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
            ),
            child: Image.file(
              imageFile,
              fit: BoxFit.contain,
            ),
          ),
          
          // Brand name if available
          if (brand.isNotEmpty && brand != 'Unknown')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                brand,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          
          // Nutritional information
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildNutritionalInfo(nutritionalValues),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionalInfo(Map<String, dynamic> nutritionalValues) {
    // Fix: Add a safety check - if the input is not the right type, convert it
    // This prevents the '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>' error
    final Map<String, dynamic> safeNutritionalValues = 
        nutritionalValues is Map<String, dynamic> 
        ? nutritionalValues 
        : Map<String, dynamic>.from(nutritionalValues);
    
    // Create a default summary even if no specific values are available
    final String summaryText = "Calories: ${safeNutritionalValues['calories'] ?? 'N/A'} kcal\n"
        "Sugar: ${safeNutritionalValues['sugar'] ?? 'N/A'} g\n"
        "Fat: ${safeNutritionalValues['fat'] ?? 'N/A'} g";
        
    if (safeNutritionalValues.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrition Facts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summaryText,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      );
    }

    final List<Widget> nutritionItems = [];
    
    // Show calories first if available
    if (safeNutritionalValues.containsKey('calories')) {
      final calories = safeNutritionalValues['calories'] is num 
          ? safeNutritionalValues['calories'].toString() 
          : '0';
      nutritionItems.add(
        _nutritionRow('Calories', '$calories kcal', null),
      );
    }
    
    // Show sugar with color coding
    if (safeNutritionalValues.containsKey('sugar')) {
      final sugar = safeNutritionalValues['sugar'] is num 
          ? safeNutritionalValues['sugar'].toDouble() 
          : 0.0;
      Color? color;
      if (sugar < 5) {
        color = Colors.green;
      } else if (sugar < 10) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }
      nutritionItems.add(
        _nutritionRow('Sugar', '${sugar}g', color),
      );
    }
    
    // Other nutritional values
    final Map<String, String> displayNames = {
      'fat': 'Fat',
      'saturatedFat': 'Saturated Fat',
      'protein': 'Protein',
      'fiber': 'Fiber',
    };
    
    displayNames.forEach((key, displayName) {
      if (safeNutritionalValues.containsKey(key)) {
        final value = safeNutritionalValues[key] is num 
            ? safeNutritionalValues[key].toString() 
            : '0';
        nutritionItems.add(
          _nutritionRow(displayName, '${value}g', null),
        );
      }
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nutrition Facts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...nutritionItems,
      ],
    );
  }

  Widget _nutritionRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 