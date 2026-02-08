import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _gramController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _mobileImage;
  Uint8List? _webImageBytes;
  String? _webImageName;
  bool _isLoading = false;
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];


  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchSubcategories();
  }
  // Dummy categories and subcategories (replace with API if needed)
  Future<void> _fetchCategories() async {
    const url = 'https://jewellery-backend-icja.onrender.com/api/categories/';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cats = List<Map<String, dynamic>>.from(data['categories'] ?? []);
        setState(() {
          _categories = cats;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchSubcategories() async {
    const url = 'https://jewellery-backend-icja.onrender.com/api/subcategories/';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subs = List<Map<String, dynamic>>.from(data['subcategories'] ?? []);
        setState(() {
          _subcategories = subs;
        });
      }
    } catch (e) {
      print('Error fetching subcategories: $e');
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

  Future<void> _addProduct() async {
    if (_titleController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _gramController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _selectedCategoryId == null ||
        _selectedSubcategoryId == null) return;

    if (!kIsWeb && _mobileImage == null) return;
    if (kIsWeb && _webImageBytes == null) return;

    setState(() => _isLoading = true);

    const url = 'https://jewellery-backend-icja.onrender.com/api/products';

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token'); // make sure token is saved during login

      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['title'] = _titleController.text;
      request.fields['price'] = _priceController.text;
      request.fields['gram'] = _gramController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['quantity'] = _quantityController.text;
      request.fields['category'] = _selectedCategoryId!;
      request.fields['subcategory'] = _selectedSubcategoryId!;

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

      // Add Authorization header if token exists
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Product added successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: ${response.body}')),
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
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _gramController,
              decoration: const InputDecoration(
                labelText: 'Gram',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              items: _categories
                  .map((cat) => DropdownMenuItem<String>(
                value: cat['_id'].toString(), // CAST TO STRING
                child: Text(cat['name'] ?? ''),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategoryId = val),
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20,),
            DropdownButtonFormField<String>(
              value: _selectedSubcategoryId,
              items: _subcategories
                  .map((sub) => DropdownMenuItem<String>(
                value: sub['_id'].toString(), // CAST TO STRING
                child: Text(sub['name'] ?? ''),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedSubcategoryId = val),
              decoration: const InputDecoration(
                labelText: 'Select Subcategory',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Image picker
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
                onPressed: _addProduct,
                child: const Text('Add Product', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}