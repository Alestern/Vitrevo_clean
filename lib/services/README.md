# OCR Service Guide

This guide explains how to use the OCR (Optical Character Recognition) services in the Vitrevo app.

## Overview

The app includes two OCR service implementations:

1. **MLKitOCRService** - Recommended implementation using Google ML Kit Text Recognition
2. **OCRService** - Legacy implementation with custom extraction logic

## Using MLKitOCRService

The `MLKitOCRService` is the recommended implementation as it leverages Google ML Kit for text recognition, which uses Apple Vision on iOS and Google ML Kit on Android.

### Basic Usage

```dart
import 'dart:io';
import '../services/mlkit_ocr_service.dart';

// Create the service
final MLKitOCRService ocrService = MLKitOCRService();

// Process an image
File imageFile = // Get image from camera or gallery
try {
  String recognizedText = await ocrService.recognizeText(imageFile);
  print('Recognized text: $recognizedText');
} catch (e) {
  print('OCR error: $e');
}

// Don't forget to dispose
@override
void dispose() {
  ocrService.dispose();
  super.dispose();
}
```

### Features

- Automatically checks text quality
- Cleans and normalizes text
- Uses Latin script recognition for optimal results with nutritional labels
- Provides meaningful error messages

## Implementation Details

The OCR service is designed to:

1. Recognize text from nutritional labels on food packaging
2. Validate the quality of the recognized text
3. Ensure the result contains enough nutritional information

## Performance Considerations

- The OCR processing happens on-device, so it's fast and works offline
- For best results, ensure the image is well-lit and the text is clearly visible
- Apple Vision on iOS provides excellent results with minimal configuration

## Error Handling

The service may throw exceptions in the following cases:
- Image quality is insufficient
- Not enough nutritional information detected
- General processing errors

Always wrap the service calls in try-catch blocks and provide appropriate feedback to the user.

## Type Safety Considerations

### Map Type Error Fix

The application previously encountered an error: `_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>'` when processing nutritional data. This happened because:

1. JSON data decoded from responses might be typed as `Map<dynamic, dynamic>` instead of `Map<String, dynamic>`
2. When passing data between widgets, type information can be lost if not explicitly specified

To prevent these errors, the following measures were implemented:

1. **Explicit type conversion**: Always use `Map<String, dynamic>.from(map)` when working with maps from JSON or external sources
2. **Type checking**: Add runtime type checks such as `if (value is Map)` before casting
3. **Default values**: Provide properly typed empty maps as defaults: `<String, dynamic>{}`
4. **Safety functions**: Create wrapper functions that sanitize input data types

Example of safe type conversion:

```dart
// Original potentially unsafe code
final nutritionalValues = data['nutritionalValues'];

// Fixed safe code
final Map<String, dynamic> safeNutritionalValues = 
    data['nutritionalValues'] is Map 
        ? Map<String, dynamic>.from(data['nutritionalValues']) 
        : <String, dynamic>{};
```

## Example

See the `OCRDemoPage` in the examples folder for a complete implementation of the OCR service. 