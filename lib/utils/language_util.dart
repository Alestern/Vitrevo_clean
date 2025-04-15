class LanguageUtil {
  static String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
  }

  static bool containsKeywords(String text, List<String> keywords) {
    final cleanedText = cleanText(text);
    return keywords.any((keyword) => cleanedText.contains(keyword.toLowerCase()));
  }
} 