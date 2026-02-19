import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jewellery_admin/add_pages/add_product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategoriesList = [];

  bool _isCategoryLoading = false;
  bool _isSubcategoryLoading = false;

  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    const url = 'https://jewellery-backend-icja.onrender.com/api/products';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          setState(() {
            _products = data;
            _isLoading = false;
          });
        } else {
          print('Unexpected API response: $data');
          setState(() => _isLoading = false);
        }
      } else {
        print('Failed to fetch products: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCategories() async {
    setState(() => _isCategoryLoading = true);
    final res = await http.get(
      Uri.parse('https://jewellery-backend-icja.onrender.com/api/categories'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _categories = List<Map<String, dynamic>>.from(data['categories']);
        _isCategoryLoading = false;
      });
    }
  }

  Future<void> _fetchSubcategoriesByCategory(String catId) async {
    print('🟧 FETCH SUBCATEGORIES START');
    print('🟧 CATEGORY ID PASSED: $catId');

    setState(() => _isSubcategoryLoading = true);

    final res = await http.get(
      Uri.parse(
        'https://jewellery-backend-icja.onrender.com/api/subcategories/',
      ),
    );

    print('🟧 SUBCATEGORY STATUS CODE: ${res.statusCode}');
    print('🟧 SUBCATEGORY RESPONSE BODY: ${res.body}');

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final allSubs =
      List<Map<String, dynamic>>.from(data['subcategories']);

      setState(() {
        _subcategoriesList = allSubs
            .where((sub) =>
        sub['category'] != null &&
            sub['category']['_id'].toString() == catId)
            .toList();

        _isSubcategoryLoading = false;
      });

      print('🟧 FILTERED SUBCATEGORY COUNT: ${_subcategoriesList.length}');
      print('🟧 SUBCATEGORY LOADING STOPPED');
    } else {
      print('❌ SUBCATEGORY API FAILED');
      setState(() {
        _subcategoriesList = [];
        _isSubcategoryLoading = false;
      });
    }
  }

  Future<void> _updateProduct({
    required String productId,
    required String title,
    required String price,
    required String quantity,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse(
          'https://jewellery-backend-icja.onrender.com/api/products/$productId'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['title'] = title;
    request.fields['price'] = price;
    request.fields['quantity'] = quantity;
    request.fields['category'] = _selectedCategoryId!;
    request.fields['subcategory'] = _selectedSubcategoryId!;

    if (_selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
            'image', _selectedImage!.path),
      );
    }

    await request.send();
    _fetchProducts();
  }

  Future<void> _deleteProduct(String productId) async {
    final url = 'https://jewellery-backend-icja.onrender.com/api/products/$productId';
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Product deleted')),
        );
        // Refresh the product list after deletion
        _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete product: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top bar: title + add button (untouched)
          Container(
            height: 60,
            width: double.infinity,
            color: Colors.blueGrey,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Products',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddProductPage()),
                    );
                    print('Add Product tapped');
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
                          'Add Product',
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

          // Product list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? const Center(
              child: Text(
                'No products found',
                style: TextStyle(fontSize: 20),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];

                String imageUrl = 'https://via.placeholder.com/150';

                if (product['mainImage'] != null &&
                    product['mainImage']['url'] != null) {
                  imageUrl = product['mainImage']['url'];
                } else if (product['images'] != null &&
                    product['images'].isNotEmpty &&
                    product['images'][0]['url'] != null) {
                  imageUrl = product['images'][0]['url'];
                }

                final title = product['title'] ?? 'No Title';
                final price = product['price'] ?? 0;
                final category = product['category']?['name'] ?? 'No Category';
                final subcategory = product['subcategory']?['name'] ?? 'No Subcategory';
                final quantity = product['quantity'] ?? 0;
                final productId = product['_id'] ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Image.network(
                      imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(title),
                    subtitle: Text(
                        'Price: ₹$price\nCategory: $category\nSubcategory: $subcategory\nQuantity: $quantity'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            final titleController =
                            TextEditingController(text: product['title']);
                            final priceController =
                            TextEditingController(text: product['price'].toString());
                            final quantityController =
                            TextEditingController(text: product['quantity'].toString());

                            _selectedCategoryId = product['category']['_id'].toString();
                            _selectedSubcategoryId = product['subcategory']['_id'].toString();

                            await _fetchCategories();
                            await _fetchSubcategoriesByCategory(_selectedCategoryId!);

                            final exists = _subcategoriesList.any(
                                  (sub) => sub['_id'].toString() == _selectedSubcategoryId,
                            );

                            if (!exists) {
                              print('⚠️ Selected subcategory not in list, resetting');
                              _selectedSubcategoryId = null;
                            }

                            print('🟦 EDIT CLICKED');
                            print('Product ID: ${product['_id']}');
                            print('Category ID (from product): ${product['category']['_id']}');
                            print('Subcategory ID (from product): ${product['subcategory']['_id']}');

                            showDialog(
                              context: context,
                              builder: (ctx) => StatefulBuilder(
                                builder: (ctx, setDialogState) => AlertDialog(
                                  title: const Text('Edit Product'),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      children: [

                                        /// IMAGE PICK
                                        GestureDetector(
                                          onTap: () async {
                                            final picked = await ImagePicker()
                                                .pickImage(source: ImageSource.gallery);
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
                                                : NetworkImage(imageUrl) as ImageProvider,
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        TextField(
                                          controller: titleController,
                                          decoration:
                                          const InputDecoration(labelText: 'Title'),
                                        ),

                                        const SizedBox(height: 12),

                                        /// CATEGORY DROPDOWN ⭐
                                        _isCategoryLoading
                                            ? const CircularProgressIndicator()
                                            : DropdownButtonFormField<String>(
                                          value: _selectedCategoryId,
                                          decoration: const InputDecoration(labelText: 'Category'),
                                          items: _categories.map((cat) {
                                            return DropdownMenuItem<String>(
                                              value: cat['_id'].toString(), // ✅ FIX
                                              child: Text(cat['name'].toString()),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setDialogState(() {
                                              _selectedCategoryId = val;
                                              _selectedSubcategoryId = null;
                                            });
                                            _fetchSubcategoriesByCategory(val!);
                                          },
                                        ),

                                        const SizedBox(height: 12),

                                        /// SUBCATEGORY DROPDOWN ⭐
                                        _isSubcategoryLoading
                                            ? const CircularProgressIndicator()
                                            : DropdownButtonFormField<String>(
                                          value: _selectedSubcategoryId,
                                          decoration: const InputDecoration(labelText: 'Subcategory'),
                                          items: _subcategoriesList.map((sub) {
                                            return DropdownMenuItem<String>(
                                              value: sub['_id'].toString(), // ✅ FIX
                                              child: Text(sub['name'].toString()),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            setDialogState(() {
                                              _selectedSubcategoryId = val;
                                            });
                                          },
                                        ),

                                        const SizedBox(height: 12),

                                        TextField(
                                          controller: priceController,
                                          decoration:
                                          const InputDecoration(labelText: 'Price'),
                                        ),

                                        TextField(
                                          controller: quantityController,
                                          decoration:
                                          const InputDecoration(labelText: 'Quantity'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _updateProduct(
                                          productId: productId,
                                          title: titleController.text,
                                          price: priceController.text,
                                          quantity: quantityController.text,
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
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text(
                                    'Are you sure you want to delete this product?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _deleteProduct(productId);
                                    },
                                    child: const Text('Delete',style: TextStyle(color: Colors.red)),
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