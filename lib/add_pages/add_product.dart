import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ── Palette (same across all pages) ───────────────────────────────────────
const _white      = Color(0xFFFFFFFF);
const _bgPage     = Color(0xFFF8F6F1);
const _bgCard     = Color(0xFFFFFFFF);
const _bgField    = Color(0xFFF4F2EC);
const _gold       = Color(0xFFB8952A);
const _goldBorder = Color(0xFFE8D99A);
const _textDark   = Color(0xFF1C1C1E);
const _textSub    = Color(0xFF6B6B6B);
const _textMuted  = Color(0xFFAAAAAA);
const _divider    = Color(0xFFEDEAE0);
const _red        = Color(0xFFD94040);
const _redBg      = Color(0xFFFFF0F0);

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _title         = TextEditingController();
  final _originalPrice = TextEditingController();
  final _price         = TextEditingController();
  final _gram          = TextEditingController();
  final _description   = TextEditingController();
  final _quantity      = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _mainImage;
  List<XFile> _extraImages = [];

  bool _loading = false;

  String? _categoryId;
  String? _subcategoryId;

  List categories    = [];
  List subcategories = [];

  final String baseUrl = 'https://jewellery-backend-icja.onrender.com/api';

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  // ── API ────────────────────────────────────────────────────────────────────
  Future<void> fetchCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/categories/'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() => categories = data['categories']);
    }
  }

  Future<void> fetchSubcategoriesByCategory(String categoryId) async {
    final res = await http.get(Uri.parse('$baseUrl/subcategories/'));
    if (res.statusCode == 200) {
      final all = jsonDecode(res.body)['subcategories'];
      setState(() {
        subcategories = all.where((s) =>
        s['category'] != null &&
            s['category']['_id'].toString() == categoryId).toList();
      });
    }
  }

  // ── Image pick ─────────────────────────────────────────────────────────────
  Future<void> pickMainImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _mainImage = img);
  }

  Future<void> pickExtraImages() async {
    final imgs = await _picker.pickMultiImage();
    if (imgs.isNotEmpty) setState(() => _extraImages.addAll(imgs));
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> addProduct() async {
    if (_mainImage == null) { _showSnack('Please select a main image'); return; }
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final request = http.MultipartRequest('POST',
          Uri.parse('$baseUrl/products/'));

      request.fields.addAll({
        'title'        : _title.text,
        'category'     : _categoryId ?? '',
        'subcategory'  : _subcategoryId ?? '',
        'originalPrice': _originalPrice.text,
        'price'        : _price.text,
        'gram'         : _gram.text,
        'description'  : _description.text,
        'quantity'     : _quantity.text,
      });

      await _addFile(request, 'mainImage', _mainImage!);
      for (final img in _extraImages) {
        await _addFile(request, 'images', img);
      }

      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      final res = await http.Response.fromStream(await request.send());

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnack('Product added successfully');
        Navigator.pop(context);
      } else {
        _showSnack('Failed: ${res.body}');
      }
    } catch (e) { _showSnack('Error: $e'); }
    setState(() => _loading = false);
  }

  Future<void> _addFile(http.MultipartRequest req, String field, XFile file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes(field, bytes, filename: file.name));
    } else {
      req.files.add(await http.MultipartFile.fromPath(field, file.path));
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
        content: Text(msg, style: const TextStyle(color: _white)),
      ));

  // ── Web-safe image preview ─────────────────────────────────────────────────
  Widget _xfilePreview(XFile xfile, {double width = 80, double height = 80}) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: xfile.readAsBytes(),
        builder: (_, snap) {
          if (snap.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: Image.memory(snap.data!,
                  width: width, height: height, fit: BoxFit.cover),
            );
          }
          return Container(width: width, height: height,
              decoration: BoxDecoration(color: _bgField,
                  borderRadius: BorderRadius.circular(1)));
        },
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Image.file(File(xfile.path),
            width: width, height: height, fit: BoxFit.cover),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: _bgCard,
        elevation: 0,
        centerTitle: false,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _bgField, borderRadius: BorderRadius.circular(1)),
            child: const Icon(Icons.arrow_back_ios_new,
                color: _textDark, size: 16),
          ),
        ),
        title: Row(children: [
          Container(width: 3, height: 20,
              decoration: BoxDecoration(color: _gold,
                  borderRadius: BorderRadius.circular(1))),
          const SizedBox(width: 10),
          const Text('ADD PRODUCT',
              style: TextStyle(color: _textDark, fontSize: 18,
                  fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _goldBorder.withOpacity(0.5)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Images Section ──────────────────────────────────────────
            _sectionCard(
              title: 'Product Images',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Main Image
                  _label('MAIN IMAGE'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: pickMainImage,
                    child: _mainImage != null
                        ? Stack(alignment: Alignment.bottomRight, children: [
                      _xfilePreview(_mainImage!, width: 100, height: 100),
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(color: _gold,
                            shape: BoxShape.circle,
                            border: Border.all(color: _white, width: 2)),
                        child: const Icon(Icons.edit, color: _white, size: 12),
                      ),
                    ])
                        : Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: _bgField,
                        borderRadius: BorderRadius.circular(1),
                        border: Border.all(color: _goldBorder,
                            style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: _gold, size: 28),
                          SizedBox(height: 4),
                          Text('Main Image',
                              style: TextStyle(color: _textMuted,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Extra Images
                  _label('EXTRA IMAGES'),
                  const SizedBox(height: 10),

                  if (_extraImages.isNotEmpty) ...[
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _extraImages.length,
                        itemBuilder: (_, i) => Stack(children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _xfilePreview(_extraImages[i]),
                          ),
                          Positioned(
                            top: 0, right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _extraImages.removeAt(i)),
                              child: Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(
                                    color: _red, shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    color: _white, size: 11),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  OutlinedButton.icon(
                    onPressed: pickExtraImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 16, color: _gold),
                    label: const Text('Add Extra Images',
                        style: TextStyle(color: _gold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _goldBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Details Section ─────────────────────────────────────────
            _sectionCard(
              title: 'Product Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field('TITLE', _title),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _field('ORIGINAL PRICE', _originalPrice,
                        isNum: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('SALE PRICE', _price, isNum: true)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _field('GRAM', _gram, isNum: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('QUANTITY', _quantity, isNum: true)),
                  ]),
                  const SizedBox(height: 14),
                  _field('DESCRIPTION', _description, maxLines: 3),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Category Section ────────────────────────────────────────
            _sectionCard(
              title: 'Category',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _label('CATEGORY'),
                  const SizedBox(height: 8),
                  _dropdown(
                    value: _categoryId,
                    hint: 'Select Category',
                    items: categories.map<DropdownMenuItem<String>>((c) =>
                        DropdownMenuItem(value: c['_id'].toString(),
                            child: Text(c['name']))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _categoryId = v;
                        _subcategoryId = null;
                        subcategories = [];
                      });
                      if (v != null) fetchSubcategoriesByCategory(v);
                    },
                  ),

                  const SizedBox(height: 14),

                  _label('SUBCATEGORY'),
                  const SizedBox(height: 8),
                  _dropdown(
                    value: _subcategoryId,
                    hint: 'Select Subcategory',
                    items: subcategories.map<DropdownMenuItem<String>>((s) =>
                        DropdownMenuItem(value: s['_id'].toString(),
                            child: Text(s['name']))).toList(),
                    onChanged: (v) => setState(() => _subcategoryId = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Submit Button ───────────────────────────────────────────
            _loading
                ? const Center(child: CircularProgressIndicator(
                color: _gold, strokeWidth: 2))
                : SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1)),
                ),
                child: const Text('Add Product',
                    style: TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Reusable helpers ───────────────────────────────────────────────────────
  Widget _sectionCard({required String title, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(1),
          border: Border.all(color: _divider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 3, height: 14,
                decoration: BoxDecoration(color: _gold,
                    borderRadius: BorderRadius.circular(1))),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: _textDark,
                fontWeight: FontWeight.w700, fontSize: 14)),
          ]),
          const SizedBox(height: 16),
          child,
        ]),
      );

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: _textMuted, letterSpacing: 1.4));

  Widget _field(String label, TextEditingController ctrl,
      {bool isNum = false, int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: _textDark, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: _bgField,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(1),
                borderSide: const BorderSide(color: _divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(1),
                borderSide: const BorderSide(color: _divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(1),
                borderSide: const BorderSide(color: _gold, width: 1.5)),
          ),
        ),
      ]);

  Widget _dropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButtonFormField<String>(
        value: value,
        dropdownColor: _bgCard,
        style: const TextStyle(color: _textDark, fontSize: 14),
        icon: const Icon(Icons.keyboard_arrow_down, color: _gold, size: 20),
        decoration: InputDecoration(
          filled: true,
          fillColor: _bgField,
          hintText: hint,
          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(1),
              borderSide: const BorderSide(color: _divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(1),
              borderSide: const BorderSide(color: _divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(1),
              borderSide: const BorderSide(color: _gold, width: 1.5)),
        ),
        items: items,
        onChanged: onChanged,
      );
}