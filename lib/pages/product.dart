import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jewellery_admin/add_pages/add_product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final res = await http.get(Uri.parse(
          'https://jewellery-backend-icja.onrender.com/api/products'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) setState(() { _products = data; _isLoading = false; });
        else setState(() => _isLoading = false);
      } else setState(() => _isLoading = false);
    } catch (_) { setState(() => _isLoading = false); }
  }

  Future<void> _fetchCategories(StateSetter set) async {
    set(() => _isCategoryLoading = true);
    try {
      final res = await http.get(Uri.parse(
          'https://jewellery-backend-icja.onrender.com/api/categories'));
      if (res.statusCode == 200) {
        set(() {
          _categories = List<Map<String, dynamic>>.from(
              jsonDecode(res.body)['categories']);
          _isCategoryLoading = false;
        });
      } else set(() => _isCategoryLoading = false);
    } catch (_) { set(() => _isCategoryLoading = false); }
  }

  Future<void> _fetchSubcategoriesByCategory(String catId, StateSetter set) async {
    set(() => _isSubcategoryLoading = true);
    try {
      final res = await http.get(Uri.parse(
          'https://jewellery-backend-icja.onrender.com/api/subcategories/'));
      if (res.statusCode == 200) {
        final all = List<Map<String, dynamic>>.from(
            jsonDecode(res.body)['subcategories']);
        set(() {
          _subcategoriesList = all.where((s) =>
          s['category'] != null &&
              s['category']['_id'].toString() == catId).toList();
          _isSubcategoryLoading = false;
        });
      } else set(() { _subcategoriesList = []; _isSubcategoryLoading = false; });
    } catch (_) { set(() { _subcategoriesList = []; _isSubcategoryLoading = false; }); }
  }

  Future<void> _updateProduct({
    required String productId,
    required String title,
    required String price,
    required String originalPrice,
    required String gram,
    required String description,
    required String quantity,
    required XFile? mainImage,
    required List<XFile> extraImages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final req = http.MultipartRequest('PUT',
        Uri.parse('https://jewellery-backend-icja.onrender.com/api/products/$productId'));
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['title']         = title;
    req.fields['price']         = price;
    req.fields['originalPrice'] = originalPrice;
    req.fields['gram']          = gram;
    req.fields['description']   = description;
    req.fields['quantity']      = quantity;
    req.fields['category']      = _selectedCategoryId!;
    req.fields['subcategory']   = _selectedSubcategoryId!;
    if (mainImage != null) {
      final bytes = await mainImage.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes(
          'mainImage', bytes, filename: mainImage.name));
    }
    for (final img in extraImages) {
      final bytes = await img.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes(
          'images', bytes, filename: img.name));
    }
    final s = await req.send();
    print('UPDATE: ${await s.stream.bytesToString()}');
    _fetchProducts();
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final res = await http.delete(
        Uri.parse('https://jewellery-backend-icja.onrender.com/api/products/$productId'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        _showSnack(jsonDecode(res.body)['message'] ?? 'Product deleted');
        _fetchProducts();
      } else {
        _showSnack('Delete failed');
      }
    } catch (e) { _showSnack('Error: $e'); }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(msg, style: const TextStyle(color: _white)),
      ));

  Widget _xfilePreview(XFile xfile, {double size = 62}) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: xfile.readAsBytes(),
        builder: (_, snap) {
          if (snap.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(snap.data!,
                  width: size, height: size, fit: BoxFit.cover),
            );
          }
          return Container(width: size, height: size,
              decoration: BoxDecoration(color: _bgField,
                  borderRadius: BorderRadius.circular(10)));
        },
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(File(xfile.path),
            width: size, height: size, fit: BoxFit.cover),
      );
    }
  }

  void _showEditDialog(Map<String, dynamic> product, String imageUrl) {
    XFile? selectedMainImage;
    List<XFile> selectedExtraImages = [];
    bool initialized = false;

    final List<String> existingExtras = [];
    for (final img in (product['images'] ?? [])) {
      if (img['url'] != null) existingExtras.add(img['url'].toString());
    }

    final titleCtrl = TextEditingController(text: product['title']);
    final priceCtrl = TextEditingController(text: product['price'].toString());
    final origCtrl  = TextEditingController(text: product['originalPrice']?.toString() ?? '');
    final gramCtrl  = TextEditingController(text: product['gram']?.toString() ?? '');
    final descCtrl  = TextEditingController(text: product['description'] ?? '');
    final qtyCtrl   = TextEditingController(text: product['quantity'].toString());

    _selectedCategoryId    = product['category']['_id'].toString();
    _selectedSubcategoryId = product['subcategory']['_id'].toString();
    _categories = []; _subcategoriesList = [];
    _isCategoryLoading = false; _isSubcategoryLoading = false;

    showDialog(
      context: context,
      barrierColor: Colors.black38,
      // ✅ KEY FIX: useSafeArea false — we control insets manually
      useSafeArea: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          if (!initialized) {
            initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await _fetchCategories(set);
              await _fetchSubcategoriesByCategory(_selectedCategoryId!, set);
            });
          }

          // ✅ KEY FIX: Read keyboard height here inside builder so it rebuilds
          final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;

          return GestureDetector(
            // ✅ Tap outside keyboard → dismiss keyboard, NOT dialog
            onTap: () => FocusScope.of(ctx).unfocus(),
            child: Padding(
              // ✅ KEY FIX: bottom padding = keyboard height → dialog moves up with keyboard
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10),
                        blurRadius: 30, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // Header
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                        decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: _divider))),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                                color: _goldBorder.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.edit_outlined, color: _gold, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text('Edit Product',
                              style: TextStyle(color: _textDark, fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(color: _bgField,
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.close, color: _textSub, size: 16),
                            ),
                          ),
                        ]),
                      ),

                      // ✅ KEY FIX: Constrained height so keyboard push doesn't
                      // cause unbounded scroll jump
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.65,
                        ),
                        child: SingleChildScrollView(
                          // ✅ Drag down on scroll area dismisses keyboard
                          keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Main Image
                              _label('MAIN IMAGE'),
                              const SizedBox(height: 10),
                              Center(
                                child: GestureDetector(
                                  onTap: () async {
                                    final p = await ImagePicker()
                                        .pickImage(source: ImageSource.gallery);
                                    if (p != null) set(() => selectedMainImage = p);
                                  },
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        width: 88, height: 88,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _goldBorder, width: 2.5),
                                        ),
                                        child: ClipOval(
                                          child: selectedMainImage != null
                                              ? _xfilePreview(selectedMainImage!, size: 88)
                                              : Image.network(imageUrl,
                                              width: 88, height: 88,
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                      Container(
                                        width: 26, height: 26,
                                        decoration: BoxDecoration(
                                            color: _gold, shape: BoxShape.circle,
                                            border: Border.all(color: _white, width: 2)),
                                        child: const Icon(Icons.edit, color: _white, size: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),
                              _label('EXTRA IMAGES'),
                              const SizedBox(height: 10),

                              if (existingExtras.isNotEmpty)
                                SizedBox(
                                  height: 66,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: existingExtras.length,
                                    itemBuilder: (_, i) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(existingExtras[i],
                                            width: 62, height: 62, fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                ),

                              if (selectedExtraImages.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 66,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: selectedExtraImages.length,
                                    itemBuilder: (_, i) => Stack(children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: _xfilePreview(selectedExtraImages[i]),
                                      ),
                                      Positioned(
                                        top: 0, right: 4,
                                        child: GestureDetector(
                                          onTap: () => set(() =>
                                              selectedExtraImages.removeAt(i)),
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
                              ],

                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await ImagePicker().pickMultiImage();
                                  if (picked.isNotEmpty)
                                    set(() => selectedExtraImages.addAll(picked));
                                },
                                icon: const Icon(Icons.add_photo_alternate_outlined,
                                    size: 16, color: _gold),
                                label: const Text('Add Extra Images',
                                    style: TextStyle(color: _gold, fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _goldBorder),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                ),
                              ),

                              const SizedBox(height: 20),
                              _field('TITLE', titleCtrl),
                              const SizedBox(height: 14),

                              _label('CATEGORY'),
                              const SizedBox(height: 8),
                              _isCategoryLoading
                                  ? _miniLoader()
                                  : _dropdown(
                                value: _selectedCategoryId,
                                hint: 'Select Category',
                                items: _categories.map((c) => DropdownMenuItem(
                                    value: c['_id'].toString(),
                                    child: Text(c['name'].toString()))).toList(),
                                onChanged: (val) {
                                  set(() {
                                    _selectedCategoryId = val;
                                    _selectedSubcategoryId = null;
                                    _subcategoriesList = [];
                                  });
                                  _fetchSubcategoriesByCategory(val!, set);
                                },
                              ),

                              const SizedBox(height: 14),
                              _label('SUBCATEGORY'),
                              const SizedBox(height: 8),
                              _isSubcategoryLoading
                                  ? _miniLoader()
                                  : _dropdown(
                                value: _selectedSubcategoryId,
                                hint: 'Select Subcategory',
                                items: _subcategoriesList.map((s) => DropdownMenuItem(
                                    value: s['_id'].toString(),
                                    child: Text(s['name'].toString()))).toList(),
                                onChanged: (val) =>
                                    set(() => _selectedSubcategoryId = val),
                              ),

                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(child: _field('PRICE', priceCtrl, isNum: true)),
                                const SizedBox(width: 12),
                                Expanded(child: _field('ORIGINAL PRICE', origCtrl, isNum: true)),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(child: _field('GRAM', gramCtrl, isNum: true)),
                                const SizedBox(width: 12),
                                Expanded(child: _field('QUANTITY', qtyCtrl, isNum: true)),
                              ]),
                              const SizedBox(height: 14),
                              _field('DESCRIPTION', descCtrl, maxLines: 3),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),

                      // Footer
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: _divider))),
                        child: Row(children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _divider),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: const Text('CANCEL',
                                  style: TextStyle(color: _textSub,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _updateProduct(
                                  productId: product['_id'],
                                  title: titleCtrl.text,
                                  price: priceCtrl.text,
                                  originalPrice: origCtrl.text,
                                  gram: gramCtrl.text,
                                  description: descCtrl.text,
                                  quantity: qtyCtrl.text,
                                  mainImage: selectedMainImage,
                                  extraImages: selectedExtraImages,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _gold,
                                foregroundColor: _white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: const Text('UPDATE',
                                  style: TextStyle(fontWeight: FontWeight.w700,
                                      fontSize: 14, letterSpacing: 0.3)),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: _textMuted, letterSpacing: 1.4));

  Widget _miniLoader() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Center(child: SizedBox(width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: _gold))),
  );

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
          // ✅ onTap — no auto scroll, we handle it manually
          onTap: () {},
          decoration: InputDecoration(
            filled: true,
            fillColor: _bgField,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _gold, width: 1.5)),
        ),
        items: items,
        onChanged: onChanged,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: 64,
            color: Colors.yellow.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(width: 3, height: 22,
                  decoration: BoxDecoration(color: _gold,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              const Text('PRODUCTS',
                  style: TextStyle(color: _textDark, fontSize: 20,
                      fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddProductPage())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADD PRODUCT',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ]),
          ),
          Container(height: 1, color: _goldBorder.withOpacity(0.5)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                color: _gold, strokeWidth: 2))
                : _products.isEmpty
                ? const Center(child: Text('No products found',
                style: TextStyle(color: _textMuted, fontSize: 16)))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _products.length,
              itemBuilder: (_, index) {
                final p = _products[index];
                String imgUrl = 'https://via.placeholder.com/150';
                if (p['mainImage']?['url'] != null)
                  imgUrl = p['mainImage']['url'];
                else if ((p['images'] ?? []).isNotEmpty &&
                    p['images'][0]['url'] != null)
                  imgUrl = p['images'][0]['url'];

                final title = p['title'] ?? 'No Title';
                final price = p['price'] ?? 0;
                final orig  = p['originalPrice'] ?? 0;
                final gram  = p['gram'] ?? 0;
                final cat   = p['category']?['name'] ?? '—';
                final sub   = p['subcategory']?['name'] ?? '—';
                final qty   = p['quantity'] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: _divider),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Image.network(imgUrl,
                              width: 100, height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  width: 100, height: 120,
                                  color: _bgField,
                                  child: const Icon(
                                      Icons.image_not_supported,
                                      color: _textMuted))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: const TextStyle(
                                      color: _textDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text('₹$price',
                                    style: const TextStyle(
                                        color: _gold,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                const SizedBox(width: 8),
                                Text('₹$orig',
                                    style: const TextStyle(
                                        color: _textMuted,
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough)),
                              ]),
                              const SizedBox(height: 8),
                              Wrap(spacing: 6, runSpacing: 4,
                                children: [
                                  _chip(cat), _chip(sub),
                                  _chip('Qty: $qty'),
                                  _chip('${gram}g'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(children: [
                          _actionBtn(
                            icon: Icons.edit_outlined,
                            color: _gold,
                            bg: _goldBorder.withOpacity(0.25),
                            onTap: () => _showEditDialog(p, imgUrl),
                          ),
                          const SizedBox(height: 8),
                          _actionBtn(
                            icon: Icons.delete_outline,
                            color: _red,
                            bg: _redBg,
                            onTap: () => _confirmDelete(p['_id']),
                          ),
                        ]),
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

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: _bgPage,
        borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: const TextStyle(
        color: _textSub, fontSize: 10, letterSpacing: 0.2)),
  );

  Widget _actionBtn({required IconData icon, required Color color,
    required Color bg, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: bg,
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 17),
        ),
      );

  void _confirmDelete(String productId) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10),
                blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: _redBg, shape: BoxShape.circle,
                  border: Border.all(color: _red.withOpacity(0.25), width: 1.5)),
              child: const Icon(Icons.delete_outline, color: _red, size: 24),
            ),
            const SizedBox(height: 16),
            const Text('Delete Product?',
                style: TextStyle(color: _textDark, fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('This action cannot be undone.',
                style: TextStyle(color: _textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _divider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: _textSub)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteProduct(productId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: _white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Delete',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}