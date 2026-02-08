import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddSubcategoryPage extends StatefulWidget {
  const AddSubcategoryPage({super.key});

  @override
  State<AddSubcategoryPage> createState() => _AddSubcategoryPageState();
}

class _AddSubcategoryPageState extends State<AddSubcategoryPage> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _mobileImage;        // Mobile
  Uint8List? _webImageBytes;  // Web
  String? _webImageName;

  bool _isLoading = false;
  String? _selectedCategoryId;

  // Dummy categories list (replace with API call if needed)
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

// Fetch categories from API
  Future<void> _fetchCategories() async {
    const url = 'https://jewellery-backend-icja.onrender.com/api/categories/';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cats = List<Map<String, dynamic>>.from(data['categories'] ?? []);
        setState(() {
          _categories = cats;
          // Set default selected category if none chosen
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories[0]['_id'].toString();
          }
        });
      } else {
        print('Failed to fetch categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

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
        } else {
          setState(() {
            _mobileImage = picked;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _addSubcategory() async {
    if (_nameController.text.isEmpty || _selectedCategoryId == null) return;
    if (!kIsWeb && _mobileImage == null) return;
    if (kIsWeb && _webImageBytes == null) return;

    setState(() => _isLoading = true);

    const url = 'https://jewellery-backend-icja.onrender.com/api/subcategories';
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll({
        'Authorization': 'Bearer $token', // <-- attach token here
        'Accept': 'application/json',
      });

      request.fields['name'] = _nameController.text;
      request.fields['categoryId'] = _selectedCategoryId!;

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Subcategory added successfully')),
        );
        Navigator.pop(context); // Go back after adding
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add subcategory: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Subcategory')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Subcategory Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              items: _categories.isNotEmpty
                  ? _categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['_id'].toString(),
                  child: Text(cat['name'] ?? ''),
                );
              }).toList()
                  : [], // empty while loading
              onChanged: (val) => setState(() => _selectedCategoryId = val),
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Image preview + picker
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

            // Add button
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addSubcategory,
                child: const Text('Add Subcategory', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}