import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jewellery_admin/add_pages/add_sub_category.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// ── Palette (same as ProductPage & CategoryPage) ───────────────────────────
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

class SubcategoryPage extends StatefulWidget {
  const SubcategoryPage({super.key});

  @override
  State<SubcategoryPage> createState() => _SubcategoryPageState();
}

class _SubcategoryPageState extends State<SubcategoryPage> {
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _categories    = [];
  bool _isLoading         = true;
  bool _isCategoryLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
    _fetchCategories();
  }

  // ── API ────────────────────────────────────────────────────────────────────
  Future<void> _fetchCategories() async {
    setState(() => _isCategoryLoading = true);
    try {
      final res = await http.get(Uri.parse(
          'https://jewellery-backend-icja.onrender.com/api/categories'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
          _isCategoryLoading = false;
        });
      } else {
        setState(() => _isCategoryLoading = false);
      }
    } catch (_) { setState(() => _isCategoryLoading = false); }
  }

  Future<void> _fetchSubcategories() async {
    try {
      final res = await http.get(Uri.parse(
          'https://jewellery-backend-icja.onrender.com/api/subcategories'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _subcategories = List<Map<String, dynamic>>.from(
              data['subcategories'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Failed: ${res.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _isLoading = false; });
    }
  }

  Future<void> _updateSubcategory({
    required String subcatId,
    required String name,
    required String categoryId,
    required XFile? image,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final req = http.MultipartRequest('PUT',
        Uri.parse('https://jewellery-backend-icja.onrender.com/api/subcategories/$subcatId'));
    req.headers['Authorization'] = 'Bearer $token';
    req.fields['name']       = name;
    req.fields['categoryId'] = categoryId;

    if (image != null) {
      final bytes = await image.readAsBytes();
      req.files.add(http.MultipartFile.fromBytes(
          'image', bytes, filename: image.name));
    }

    try {
      final res = await req.send();
      if (res.statusCode == 200) {
        _showSnack('Subcategory updated successfully');
        _fetchSubcategories();
      } else {
        _showSnack('Update failed');
      }
    } catch (e) { _showSnack('Error: $e'); }
  }

  Future<void> _deleteSubcategory(String subcatId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    try {
      final res = await http.delete(
        Uri.parse('https://jewellery-backend-icja.onrender.com/api/subcategories/$subcatId'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        _showSnack('Subcategory deleted successfully');
        _fetchSubcategories();
      } else {
        _showSnack('Delete failed: ${res.statusCode}');
      }
    } catch (e) { _showSnack('Error: $e'); }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(1)),
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
              ? const Icon(Icons.hourglass_empty, color: _textMuted) : null,
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
  void _showEditDialog(Map<String, dynamic> subcat) {
    XFile? selectedImage;
    final nameCtrl   = TextEditingController(text: subcat['name'] ?? '');
    final subcatId   = subcat['_id'] ?? '';
    final imageUrl   = subcat['image']?['url'] ?? '';

    // Pre-select current category
    String? selectedCatId = subcat['category'] is String
        ? subcat['category']
        : subcat['category']?['_id'];

    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Container(
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(1),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 30, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Header ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _divider))),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: _goldBorder.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(1)),
                      child: const Icon(Icons.edit_outlined, color: _gold, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text('Edit Subcategory',
                        style: TextStyle(color: _textDark, fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(color: Colors.red,
                            borderRadius: BorderRadius.circular(1)),
                        child: const Icon(Icons.close, color: _textSub, size: 16),
                      ),
                    ),
                  ]),
                ),

                // ── Body ─────────────────────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Image picker
                        Center(
                          child: GestureDetector(
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
                                      ? const Icon(Icons.layers_outlined,
                                      color: _textMuted, size: 28)
                                      : null,
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

                        // Subcategory Name
                        _label('SUBCATEGORY NAME'),
                        const SizedBox(height: 6),
                        _textField(nameCtrl),

                        const SizedBox(height: 16),

                        // Category Dropdown
                        _label('CATEGORY'),
                        const SizedBox(height: 6),
                        _isCategoryLoading
                            ? const Center(child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _gold)))
                            : DropdownButtonFormField<String>(
                          value: selectedCatId,
                          dropdownColor: _bgCard,
                          style: const TextStyle(color: _textDark, fontSize: 14),
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: _gold, size: 20),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _bgField,
                            hintText: 'Select Category',
                            hintStyle: const TextStyle(
                                color: _textMuted, fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(1),
                                borderSide: const BorderSide(color: _divider)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(1),
                                borderSide: const BorderSide(color: _divider)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(1),
                                borderSide: const BorderSide(
                                    color: _gold, width: 1.5)),
                          ),
                          items: _categories.map((cat) => DropdownMenuItem(
                              value: cat['_id'].toString(),
                              child: Text(cat['name'].toString()))).toList(),
                          onChanged: (val) =>
                              set(() => selectedCatId = val),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Footer ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _divider),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1)),
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
                          _updateSubcategory(
                            subcatId: subcatId,
                            name: nameCtrl.text,
                            categoryId: selectedCatId ?? '',
                            image: selectedImage,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1)),
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
  void _confirmDelete(String subcatId) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(1),
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
            const Text('Delete Subcategory?',
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
                        borderRadius: BorderRadius.circular(1)),
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
                    _deleteSubcategory(subcatId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: _white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(1)),
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

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: _textMuted, letterSpacing: 1.4));

  Widget _textField(TextEditingController ctrl) => TextField(
    controller: ctrl,
    style: const TextStyle(color: _textDark, fontSize: 14),
    decoration: InputDecoration(
      filled: true,
      fillColor: _bgField,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: _divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: _divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(1),
          borderSide: const BorderSide(color: _gold, width: 1.5)),
    ),
  );

  Widget _actionBtn({required IconData icon, required Color color,
    required Color bg, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: bg,
              borderRadius: BorderRadius.circular(1)),
          child: Icon(icon, color: color, size: 17),
        ),
      );

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
              const Text('SUBCATEGORIES',
                  style: TextStyle(color: _textDark, fontSize: 20,
                      fontWeight: FontWeight.w700, letterSpacing: 0.3)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const AddSubcategoryPage()));
                  _fetchSubcategories();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADD SUBCATEGORY',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(1)),
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
                : _subcategories.isEmpty
                ? const Center(child: Text('No subcategories found',
                style: TextStyle(color: _textMuted, fontSize: 16)))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _subcategories.length,
              itemBuilder: (_, index) {
                final sub = _subcategories[index];
                final imageUrl = sub['image']?['url'] ?? '';
                final name     = sub['name'] ?? '';
                final catName  = sub['category']?['name'] ?? '—';
                final subcatId = sub['_id'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(1),
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

                      // Image
                      imageUrl.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: Image.network(imageUrl,
                            width: 56, height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholderIcon()),
                      )
                          : _placeholderIcon(),

                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            // Category chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: _goldBorder.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(1)),
                              child: Text(catName,
                                  style: const TextStyle(
                                      color: _gold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      _actionBtn(
                        icon: Icons.edit_outlined,
                        color: _gold,
                        bg: _goldBorder.withOpacity(0.25),
                        onTap: () => _showEditDialog(sub),
                      ),
                      const SizedBox(width: 8),
                      _actionBtn(
                        icon: Icons.delete_outline,
                        color: _red,
                        bg: _redBg,
                        onTap: () => _confirmDelete(subcatId),
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
    decoration: BoxDecoration(color: _bgField,
        borderRadius: BorderRadius.circular(1)),
    child: const Icon(Icons.layers_outlined, color: _textMuted, size: 26),
  );
}