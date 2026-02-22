import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile?      _mobileImage;
  Uint8List?  _webImageBytes;
  String?     _webImageName;
  bool        _isLoading = false;

  // ── Image pick ─────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() { _webImageBytes = bytes; _webImageName = picked.name; });
        } else {
          setState(() => _mobileImage = picked);
        }
      }
    } catch (e) {
      _showSnack('Error picking image: $e');
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _addCategory() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Please enter a category name'); return;
    }
    if (!kIsWeb && _mobileImage == null) {
      _showSnack('Please select an image'); return;
    }
    if (kIsWeb && _webImageBytes == null) {
      _showSnack('Please select an image'); return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final req = http.MultipartRequest('POST',
          Uri.parse('https://jewellery-backend-icja.onrender.com/api/categories'));
      req.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      req.fields['name'] = _nameController.text;

      if (kIsWeb && _webImageBytes != null) {
        req.files.add(http.MultipartFile.fromBytes(
            'image', _webImageBytes!, filename: _webImageName!));
      } else if (_mobileImage != null) {
        req.files.add(await http.MultipartFile.fromPath(
            'image', _mobileImage!.path));
      }

      final res = await http.Response.fromStream(await req.send());

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnack('Category added successfully');
        _nameController.clear();
        setState(() {
          _mobileImage = null;
          _webImageBytes = null;
          _webImageName = null;
        });
        Navigator.pop(context);
      } else {
        _showSnack('Failed: ${res.body}');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _textDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(msg, style: const TextStyle(color: _white)),
      ));

  bool get _hasImage => kIsWeb ? _webImageBytes != null : _mobileImage != null;

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
                color: _bgField, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.arrow_back_ios_new,
                color: _textDark, size: 16),
          ),
        ),
        title: Row(children: [
          Container(width: 3, height: 20,
              decoration: BoxDecoration(color: _gold,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          const Text('Add Category',
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

            // ── Image Section ───────────────────────────────────────────
            _sectionCard(
              title: 'Category Image',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Image preview / placeholder
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: _hasImage
                          ? Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? Image.memory(_webImageBytes!,
                                width: 140, height: 140,
                                fit: BoxFit.cover)
                                : Image.file(File(_mobileImage!.path),
                                width: 140, height: 140,
                                fit: BoxFit.cover),
                          ),
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                                color: _gold, shape: BoxShape.circle,
                                border: Border.all(color: _white, width: 2)),
                            child: const Icon(Icons.edit,
                                color: _white, size: 14),
                          ),
                        ],
                      )
                          : Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          color: _bgField,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _goldBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: _gold, size: 36),
                            SizedBox(height: 8),
                            Text('Tap to select',
                                style: TextStyle(color: _textMuted,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Change image button
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library_outlined,
                          size: 16, color: _gold),
                      label: Text(
                          _hasImage ? 'Change Image' : 'Select Image',
                          style: const TextStyle(color: _gold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _goldBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Details Section ─────────────────────────────────────────
            _sectionCard(
              title: 'Category Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('CATEGORY NAME'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: _textDark, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _bgField,
                      hintText: 'e.g. Rings, Necklaces...',
                      hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
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
            ),

            const SizedBox(height: 28),

            // ── Submit ──────────────────────────────────────────────────
            _isLoading
                ? const Center(child: CircularProgressIndicator(
                color: _gold, strokeWidth: 2))
                : SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _addCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add Category',
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

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionCard({required String title, required Widget child}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _divider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 3, height: 14,
                decoration: BoxDecoration(color: _gold,
                    borderRadius: BorderRadius.circular(2))),
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
}