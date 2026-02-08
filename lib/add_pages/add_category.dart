import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final TextEditingController _nameController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _mobileImage;        // Mobile
  Uint8List? _webImageBytes;  // Web
  String? _webImageName;

  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _webImageName = picked.name;
          });
          print('Web image selected: $_webImageName, size: ${_webImageBytes!.length}');
        } else {
          setState(() {
            _mobileImage = picked;
          });
          print('Mobile image selected: ${_mobileImage!.path}');
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _addCategory() async {
    if (_nameController.text.isEmpty) return;
    if (!kIsWeb && _mobileImage == null) return;
    if (kIsWeb && _webImageBytes == null) return;

    setState(() => _isLoading = true);

    const url = 'https://jewellery-backend-icja.onrender.com/api/categories';
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final myToken = prefs.getString('auth_token') ?? '';

      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers.addAll({
        'Authorization': 'Bearer $myToken',
        'Accept': 'application/json',
      });

      request.fields['name'] = _nameController.text;

      if (kIsWeb && _webImageBytes != null && _webImageName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _webImageBytes!,
          filename: _webImageName!,
        ));
      } else if (_mobileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _mobileImage!.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      print('Status: ${response.statusCode}, Body: ${response.body}');
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Category')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 100, vertical: 40),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            (_mobileImage != null || _webImageBytes != null)
                ? kIsWeb
                ? Image.memory(_webImageBytes!, height: 150)
                : Image.file(File(_mobileImage!.path), height: 150)
                : const SizedBox(height: 150, child: Center(child: Text('No image selected'))),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Image'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addCategory,
                child: const Text('Add Category', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}