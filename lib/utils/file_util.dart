import 'dart:io';
import 'package:flutter/foundation.dart';

class FileUtil {
  static Future<void> cleanupTemporaryFiles(List<File> imageFiles) async {
    for (var file in imageFiles) {
      try {
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted temporary file: ${file.path}');
        }
      } catch (e) {
        debugPrint('Error deleting file ${file.path}: $e');
      }
    }
  }
} 