import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jewellery_admin/add_pages/add_sub_category.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SubcategoryPage extends StatefulWidget {
  const SubcategoryPage({super.key});

  @override
  State<SubcategoryPage> createState() => _SubcategoryPageState();
}

class _SubcategoryPageState extends State<SubcategoryPage> {
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isCategoryLoading = false;
  File? _selectedImage;
  String? _selectedCategoryId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    const url = 'https://jewellery-backend-icja.onrender.com/api/categories';

    try {
      setState(() => _isCategoryLoading = true);

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categories =
          List<Map<String, dynamic>>.from(data['categories'] ?? []);
          _isCategoryLoading = false;
        });
      }
    } catch (e) {
      _isCategoryLoading = false;
    }
  }

  Future<void> _fetchSubcategories() async {
    const url = 'https://jewellery-backend-icja.onrender.com/api/subcategories';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract subcategories list
        final List<Map<String, dynamic>> subcatList =
        List<Map<String, dynamic>>.from(data['subcategories'] ?? []);

        setState(() {
          _subcategories = subcatList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load subcategories: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching subcategories: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSubcategory({
    required String subcatId,
    required String name,
    required String categoryId,
    File? image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final myToken = prefs.getString('auth_token') ?? '';

    final uri = Uri.parse(
      'https://jewellery-backend-icja.onrender.com/api/subcategories/$subcatId',
    );

    try {
      final request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $myToken';

      request.fields['name'] = name;
      request.fields['categoryId'] = categoryId;

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategory updated successfully')),
        );
        _selectedImage = null;
        _fetchSubcategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $body')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update error: $e')),
      );
    }

  }

  // DELETE subcategory by id
  Future<void> _deleteSubcategory(String subcatId) async {
    final url = 'https://jewellery-backend-icja.onrender.com/api/subcategories/$subcatId';
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final myToken = prefs.getString('auth_token') ?? '';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $myToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subcategory deleted successfully')),
        );
        _fetchSubcategories(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete subcategory: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting subcategory: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryController =
    TextEditingController(text: _selectedCategoryId);

    return Scaffold(
      body: Column(
        children: [
          // Top bar: title + add button
          Container(
            height: 60,
            width: double.infinity,
            color: Colors.blueGrey,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Subcategories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddSubcategoryPage()),
                    );
                    // Refresh list after returning from AddSubcategoryPage
                    _fetchSubcategories();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Add Subcategory',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Subcategory list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _subcategories.isEmpty
                ? const Center(child: Text('No subcategories found'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _subcategories.length,
              itemBuilder: (context, index) {
                final subcat = _subcategories[index];
                final imageUrl = subcat['image']?['url'] ?? '';
                final name = subcat['name'] ?? '';
                final categoryName = subcat['category']?['name'] ?? '';
                final subcatId = subcat['_id'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.image),
                    title: Text(name),
                    subtitle: Text('Category: $categoryName'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            final nameController = TextEditingController(text: name);
                            _selectedCategoryId = subcat['category'] is String
                                ? subcat['category']
                                : subcat['category']?['_id'];

                            showDialog(
                              context: context,
                              builder: (ctx) => StatefulBuilder(
                                builder: (ctx, setDialogState) => AlertDialog(
                                  title: const Text('Edit Subcategory'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // IMAGE PICK
                                        GestureDetector(
                                          onTap: () async {
                                            final picker = ImagePicker();
                                            final picked =
                                            await picker.pickImage(source: ImageSource.gallery);
                                            if (picked != null) {
                                              setDialogState(() {
                                                _selectedImage = File(picked.path);
                                              });
                                            }
                                          },
                                          child: CircleAvatar(
                                            radius: 35,
                                            backgroundImage: _selectedImage != null
                                                ? FileImage(_selectedImage!)
                                                : imageUrl.isNotEmpty
                                                ? NetworkImage(imageUrl)
                                                : null,
                                            child: _selectedImage == null && imageUrl.isEmpty
                                                ? const Icon(Icons.camera_alt)
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // NAME
                                        TextField(
                                          controller: nameController,
                                          decoration:
                                          const InputDecoration(labelText: 'Subcategory Name'),
                                        ),
                                        const SizedBox(height: 12),

                                        const SizedBox(height: 12),

// CATEGORY DROPDOWN ⭐⭐⭐
                                        _isCategoryLoading
                                            ? const CircularProgressIndicator()
                                            : DropdownButtonFormField<String>(
                                          value: _selectedCategoryId, // already selected category
                                          decoration: const InputDecoration(
                                            labelText: 'Category',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: _categories.map((cat) {
                                            return DropdownMenuItem<String>(
                                              value: cat['_id'],        // backend expects ID
                                              child: Text(cat['name']), // show name
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setDialogState(() {
                                              _selectedCategoryId = val;
                                            });
                                          },
                                        ),
                                        TextField(
                                          controller: categoryController,
                                          decoration: const InputDecoration(labelText: 'Category ID'),
                                          onChanged: (val) {
                                            _selectedCategoryId = val;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        _selectedImage = null;
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _updateSubcategory(
                                          subcatId: subcatId,
                                          name: nameController.text,
                                          categoryId: _selectedCategoryId ?? '',
                                          image: _selectedImage,
                                        );
                                      },
                                      child: const Text('Update'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Confirm before deleting
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Subcategory'),
                                content: const Text('Are you sure you want to delete this subcategory?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _deleteSubcategory(subcatId);
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}