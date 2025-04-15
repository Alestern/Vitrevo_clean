import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'analysis_loading_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _productA;
  File? _productB;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isProductA, ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        if (isProductA) {
          _productA = File(image.path);
        } else {
          _productB = File(image.path);
        }
      });
    }
  }

  bool get _canCompare => _productA != null && _productB != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vitrevo — Compare Products')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProductCard('Product A', _productA, () {
              _showImagePickerDialog(true);
            }),
            const SizedBox(height: 16),
            _buildProductCard('Product B', _productB, () {
              _showImagePickerDialog(false);
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: _canCompare ? _onCompare : null,
              child: const Text('Compare'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(String label, File? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Center(
            child: image != null
                ? Image.file(image, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo, size: 40),
                      const SizedBox(height: 8),
                      Text('Add photo for $label'),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showImagePickerDialog(bool isProductA) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isProductA, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(isProductA, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onCompare() {
    print('[DEBUG] Compare button clicked, navigating to analysis page');
    
    // Check if the navigation is already in progress
    if (_productA == null || _productB == null) {
      print('[ERROR] Cannot compare: product images missing');
      return;
    }
    
    // Use safe navigation pattern for iOS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => AnalysisLoadingPage(
            imageFile1: _productA!,
            imageFile2: _productB!,
            productName1: 'Product A',
            productName2: 'Product B',
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    });
  }
}