import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jewellery_admin/add_pages/add_category.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// ── Palette (same as ProductPage) ─────────────────────────────────────────
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

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    const url = 'https://jewellery-backend-icja.onrender.com/api/categories';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> list = [];
        if (data.containsKey('category')) {
          list.add(data['category']);
        } else if (data.containsKey('categories')) {
          list = List<Map<String, dynamic>>.from(data['categories']);
        }
        setState(() { _categories = list; _isLoading = false; });
      } else {
        setState(() {
          _error = 'Failed to load: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _isLoading = false; });
    }
  }

  Future<void> _updateCategory(
      String categoryId, String name, XFile? image) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final req = http.MultipartRequest('PUT',
        Uri.parse('https://jewellery-backend-icja.onrender.com/api/categories/$categoryId'));
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['name'] = name;

    // ✅ XFile — web + mobile safe
    if (image != null) {
      final bytes = await image.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes(
          'image', bytes, filename: image.name));
    }

    try {
      final res = await req.send();
      if (res.statusCode == 200) {
        _showSnack('Category updated successfully');
        _fetchCategories();
      } else {
        _showSnack('Update failed');
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    try {
      final res = await http.delete(
        Uri.parse('https://jewellery-backend-icja.onrender.com/api/categories/$categoryId'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        _showSnack('Category deleted successfully');
        _fetchCategories();
      } else {
        _showSnack('Delete failed: ${res.statusCode}');
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(msg, style: const TextStyle(color: _white)),
      ));

  // ── Web-safe image preview ─────────────────────────────────────────────────
  Widget _xfileCirclePreview(XFile xfile, {double radius = 44}) {
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: xfile.readAsBytes(),
        builder: (_, snap) => CircleAvatar(
          radius: radius,
          backgroundColor: _bgField,
          backgroundImage: snap.hasData ? MemoryImage(snap.data!) : null,
          child: !snap.hasData
              ? const Icon(Icons.hourglass_empty, color: _textMuted)
              : null,
        ),
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(xfile.path)),
      );
    }
  }

  // ── Edit Dialog ────────────────────────────────────────────────────────────
  void _showEditDialog(Map<String, dynamic> category) {
    XFile? selectedImage;
    final nameCtrl = TextEditingController(text: category['name'] ?? '');
    final categoryId = category['_id'] ?? '';
    final imageUrl = category['image']?['url'] ?? '';

    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
          child: Container(
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.10),
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
                    const Text('Edit Category',
                        style: TextStyle(color: _textDark, fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                            color: _bgField,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close, color: _textSub, size: 16),
                      ),
                    ),
                  ]),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [

                    // Image picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (picked != null) set(() => selectedImage = picked);
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          selectedImage != null
                              ? _xfileCirclePreview(selectedImage!, radius: 44)
                              : CircleAvatar(
                            radius: 44,
                            backgroundColor: _bgField,
                            backgroundImage: imageUrl.isNotEmpty
                                ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.category_outlined,
                                color: _textMuted, size: 28)
                                : null,
                          ),
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                                color: _gold,
                                shape: BoxShape.circle,
                                border: Border.all(color: _white, width: 2)),
                            child: const Icon(Icons.edit, color: _white, size: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Name field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CATEGORY NAME',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: _textMuted, letterSpacing: 1.4)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameCtrl,
                          style: const TextStyle(color: _textDark, fontSize: 14),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _bgField,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _divider)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _divider)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _gold, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                        child: const Text('Cancel',
                            style: TextStyle(color: _textSub,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _updateCategory(categoryId, nameCtrl.text, selectedImage);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text('Update',
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
  }

  // ── Delete Confirm ─────────────────────────────────────────────────────────
  void _confirmDelete(String categoryId) {
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
            const Text('Delete Category?',
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
                    _deleteCategory(categoryId);
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [

          // Top Bar
          Container(
            height: 64,
            color: Colors.yellow.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(width: 3, height: 22,
                  decoration: BoxDecoration(color: _gold,
                      borderRadius: BorderRadius.circular(1))),
              const SizedBox(width: 12),
              const Text('CATEGORIES',
                  style: TextStyle(color: _textDark, fontSize: 20,
                      fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddCategoryPage()));
                  _fetchCategories();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADD CATEGORY',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ]),
          ),
          Container(height: 1, color: _goldBorder.withOpacity(0.5)),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(
                color: _gold, strokeWidth: 2))
                : _error != null
                ? Center(child: Text(_error!,
                style: const TextStyle(color: _textMuted)))
                : _categories.isEmpty
                ? const Center(child: Text('No categories found',
                style: TextStyle(color: _textMuted, fontSize: 16)))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _categories.length,
              itemBuilder: (_, index) {
                final cat = _categories[index];
                final imageUrl = cat['image']?['url'] ?? '';
                final name = cat['name'] ?? '';
                final categoryId = cat['_id'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _divider),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(children: [

                      // Category image
                      imageUrl.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imageUrl,
                            width: 56, height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholderIcon()),
                      )
                          : _placeholderIcon(),

                      const SizedBox(width: 14),

                      // Name
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                color: _textDark,
                                fontWeight: FontWeight.w600,
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),

                      // Action buttons
                      _actionBtn(
                        icon: Icons.edit_outlined,
                        color: _gold,
                        bg: _goldBorder.withOpacity(0.25),
                        onTap: () => _showEditDialog(cat),
                      ),
                      const SizedBox(width: 8),
                      _actionBtn(
                        icon: Icons.delete_outline,
                        color: _red,
                        bg: _redBg,
                        onTap: () => _confirmDelete(categoryId),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderIcon() => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(
        color: _bgField, borderRadius: BorderRadius.circular(12)),
    child: const Icon(Icons.category_outlined, color: _textMuted, size: 26),
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
}