import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _title = TextEditingController();
  final _originalPrice = TextEditingController();
  final _price = TextEditingController();
  final _gram = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _mainImage;
  List<XFile> _extraImages = [];

  bool _loading = false;

  String? _categoryId;
  String? _subcategoryId;

  List categories = [];
  List subcategories = [];

  final String baseUrl =
      "https://jewellery-backend-icja.onrender.com/api";

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  // ================= FETCH DATA =================

  Future<void> fetchCategories() async {
    final res = await http.get(Uri.parse("$baseUrl/categories/"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() => categories = data["categories"]);
    }
  }

  Future<void> fetchSubcategoriesByCategory(String categoryId) async {
    final res = await http.get(Uri.parse("$baseUrl/subcategories/"));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final allSubs = data["subcategories"];

      setState(() {
        subcategories = allSubs
            .where((sub) =>
        sub["category"] != null &&
            sub["category"]["_id"].toString() == categoryId)
            .toList();
      });
    }
  }

  // ================= IMAGE PICK =================

  Future<void> pickMainImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _mainImage = img);
    }
  }

  Future<void> pickExtraImages() async {
    final imgs = await _picker.pickMultiImage();

    if (imgs.isNotEmpty) {
      setState(() {
        _extraImages.addAll(imgs); // IMPORTANT: append
      });

      print("Total extra images: ${_extraImages.length}");
    }
  }

  // ================= ADD PRODUCT =================

  Future<void> addProduct() async {
    if (_mainImage == null) {
      showMsg("Select Main Image");
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/products/"),
      );

      // -------- TEXT FIELDS --------
      request.fields.addAll({
        "title": _title.text,
        "category": _categoryId ?? "",
        "subcategory": _subcategoryId ?? "",
        "originalPrice": _originalPrice.text,
        "price": _price.text,
        "gram": _gram.text,
        "description": _description.text,
        "quantity": _quantity.text,
      });

      // -------- MAIN IMAGE --------
      await addImageToRequest(
        request,
        field: "mainImage",
        file: _mainImage!,
      );

      // -------- EXTRA IMAGES MULTIPLE --------
      for (var img in _extraImages) {
        await addImageToRequest(
          request,
          field: "images", // IMPORTANT: same field name repeat
          file: img,
        );
      }

      print("Total files sending: ${request.files.length}");

      // -------- TOKEN --------
      if (token != null) {
        request.headers["Authorization"] = "Bearer $token";
      }

      final response = await request.send();
      final res = await http.Response.fromStream(response);

      print(res.statusCode);
      print(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        showMsg("✅ Product Added Successfully");
        Navigator.pop(context);
      } else {
        showMsg(res.body);
      }
    } catch (e) {
      showMsg("Error: $e");
    }

    setState(() => _loading = false);
  }

  // ================= IMAGE HELPER =================

  Future<void> addImageToRequest(
      http.MultipartRequest request, {
        required String field,
        required XFile file,
      }) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          field,
          bytes,
          filename: file.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          field,
          file.path,
        ),
      );
    }
  }

  // ================= UI HELPERS =================

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget input(TextEditingController c, String label,
      {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget imagePreview() {
    if (_mainImage == null) {
      return const Text("No Image Selected");
    }

    if (kIsWeb) {
      return Image.network(_mainImage!.path, height: 150);
    }

    return Image.file(File(_mainImage!.path), height: 150);
  }

  Widget extraImagesPreview() {
    if (_extraImages.isEmpty) return const SizedBox();

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _extraImages.length,
        itemBuilder: (context, index) {
          final img = _extraImages[index];

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: kIsWeb
                    ? Image.network(img.path, height: 100)
                    : Image.file(File(img.path), height: 100),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _extraImages.removeAt(index);
                    });
                  },
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close,
                        size: 14, color: Colors.white),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            input(_title, "Title"),
            input(_originalPrice, "Original Price",
                type: TextInputType.number),
            input(_price, "Sale Price", type: TextInputType.number),
            input(_gram, "Gram", type: TextInputType.number),
            input(_quantity, "Quantity",
                type: TextInputType.number),
            input(_description, "Description"),

            DropdownButtonFormField<String>(
              value: _categoryId,
              items: categories
                  .map<DropdownMenuItem<String>>(
                    (c) => DropdownMenuItem(
                  value: c["_id"].toString(),
                  child: Text(c["name"]),
                ),
              )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _categoryId = v;
                  _subcategoryId = null; // reset
                  subcategories = [];
                });

                if (v != null) {
                  fetchSubcategoriesByCategory(v);
                }
              },
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              value: _subcategoryId,
              items: subcategories
                  .map<DropdownMenuItem<String>>(
                    (s) => DropdownMenuItem(
                  value: s["_id"].toString(),
                  child: Text(s["name"]),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => _subcategoryId = v),
              decoration: const InputDecoration(
                labelText: "Subcategory",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            imagePreview(),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: pickMainImage,
              child: const Text("Select Main Image"),
            ),

            const SizedBox(height: 10),

            extraImagesPreview(),

            ElevatedButton(
              onPressed: pickExtraImages,
              child: const Text("Select Extra Images"),
            ),

            const SizedBox(height: 30),

            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Add Product",
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}