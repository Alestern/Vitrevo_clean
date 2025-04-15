import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatelessWidget {
  final Function(File) onImageCaptured;
  final String title;

  const CameraScreen({
    Key? key,
    required this.onImageCaptured,
    this.title = 'Take a photo',
  }) : super(key: key);

  Future<void> _openCamera(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100, // Maximum quality
    );

    if (image != null && context.mounted) {
      onImageCaptured(File(image.path));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Open camera immediately when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera(context);
    });
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Opening camera...'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _openCamera(context),
              child: const Text('Open Camera Again'),
            ),
          ],
        ),
      ),
    );
  }
} 