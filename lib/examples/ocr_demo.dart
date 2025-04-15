import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/mlkit_ocr_service.dart';

class OCRDemoPage extends StatefulWidget {
  const OCRDemoPage({Key? key}) : super(key: key);

  @override
  State<OCRDemoPage> createState() => _OCRDemoPageState();
}

class _OCRDemoPageState extends State<OCRDemoPage> {
  final MLKitOCRService _ocrService = MLKitOCRService();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String _recognizedText = '';
  bool _isProcessing = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image != null) {
        setState(() {
          _image = File(image.path);
          _recognizedText = '';
          _errorMessage = '';
        });
        _processImage();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
      _recognizedText = '';
      _errorMessage = '';
    });

    try {
      final text = await _ocrService.recognizeText(_image!);
      setState(() {
        _recognizedText = text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Image.file(_image!, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _getImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _getImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage.isNotEmpty)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              )
            else if (_recognizedText.isNotEmpty) ...[
              const Text(
                'Recognized Text:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(_recognizedText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 