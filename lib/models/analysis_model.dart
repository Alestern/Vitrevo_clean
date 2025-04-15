class AnalysisModel {
  final String product1Text;
  final String product2Text;
  final String comparisonResult;

  AnalysisModel({
    required this.product1Text,
    required this.product2Text,
    required this.comparisonResult,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      product1Text: json['product1Text'] ?? '',
      product2Text: json['product2Text'] ?? '',
      comparisonResult: json['comparisonResult'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product1Text': product1Text,
      'product2Text': product2Text,
      'comparisonResult': comparisonResult,
    };
  }
} 