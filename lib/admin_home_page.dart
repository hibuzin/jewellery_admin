import 'package:flutter/material.dart';
import 'package:jewellery_admin/login.dart';
import 'package:jewellery_admin/pages/advertisement.dart';
import 'package:jewellery_admin/pages/category.dart';
import 'package:jewellery_admin/pages/order.dart';
import 'package:jewellery_admin/pages/product.dart';
import 'package:jewellery_admin/pages/sub_category.dart';

// ── Palette (same across all pages) ───────────────────────────────────────
const _white      = Color(0xFFFFFFFF);
const _bgPage     = Color(0xFFF8F6F1);
const _bgCard     = Color(0xFFFFFFFF);
const _gold       = Color(0xFFB8952A);
const _goldBorder = Color(0xFFE8D99A);
const _textDark   = Color(0xFF1C1C1E);
const _textSub    = Color(0xFF6B6B6B);
const _textMuted  = Color(0xFFAAAAAA);
const _divider    = Color(0xFFEDEAE0);
const _red        = Color(0xFFD94040);

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Menu items: icon, title, subtitle, page
    final List<_MenuItem> items = [
      _MenuItem(Icons.receipt_long_outlined,  'ORDER',        'Manage customer orders',   0),
      _MenuItem(Icons.category_outlined,      'CATEGORIES',    'Manage product categories', 1),
      _MenuItem(Icons.layers_outlined,        'SUBCATEGORIES', 'Manage subcategories',     2),
      _MenuItem(Icons.diamond_outlined,       'PRODUCTS',      'Manage jewellery items',   3),
      _MenuItem(Icons.campaign_outlined,      'ADVERTISEMENT', 'Manage banners & ads',     4),
      _MenuItem(Icons.info_outline,           'ABOUT',         'App info & settings',      5),
    ];

    void onTap(BuildContext ctx, int index) {
      switch (index) {
        case 0: Navigator.push(ctx, MaterialPageRoute(builder: (_) => OrderPage())); break;
        case 1: Navigator.push(ctx, MaterialPageRoute(builder: (_) => CategoryPage())); break;
        case 2: Navigator.push(ctx, MaterialPageRoute(builder: (_) => SubcategoryPage())); break;
        case 3: Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProductPage())); break;
        case 4: Navigator.push(ctx, MaterialPageRoute(builder: (_) => AdvertisementPage())); break;
        case 5: break;
      }
    }

    return Scaffold(
      backgroundColor: _bgPage,
      body: Column(
        children: [

          // ── Top Bar ─────────────────────────────────────────────────────
          Container(
            color: _bgCard,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 14,
              left: 20,
              right: 20,
            ),
            child: Row(children: [
              // Logo / brand mark
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(1),
                ),
                child: const Icon(Icons.diamond_outlined,
                    color: _white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Admin Panel',
                    style: TextStyle(color: _textDark, fontSize: 16,
                        fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                const Text('Jewellery Management',
                    style: TextStyle(color: _textMuted, fontSize: 11)),
              ]),
            ]),
          ),
          Container(height: 1, color: _goldBorder.withOpacity(0.5)),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 40, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Welcome banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [BoxShadow(
                          color: _gold.withOpacity(0.30),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('WELCOME BACK ',
                                style: TextStyle(color: _white,
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Manage your jewellery store from here.',
                                style: TextStyle(color: _white,
                                    fontSize: 12, fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ),
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                            color: _white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(1)),
                        child: const Icon(Icons.store_outlined,
                            color: _white, size: 28),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  // Section label
                  Row(children: [
                    Container(width: 3, height: 16,
                        decoration: BoxDecoration(color: _gold,
                            borderRadius: BorderRadius.circular(1))),
                    const SizedBox(width: 8),
                    const Text('Quick Access',
                        style: TextStyle(color: _textDark,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ]),

                  const SizedBox(height: 16),

                  // ── Menu Grid ─────────────────────────────────────────
                  Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: List.generate(items.length, (i) {
                      final item = items[i];
                      final double cardWidth = isMobile
                          ? (MediaQuery.of(context).size.width - 46) / 2
                          : (MediaQuery.of(context).size.width - 80 - 14 * 2) / 3;

                      return GestureDetector(
                        onTap: () => onTap(context, item.index),
                        child: Container(
                          width: cardWidth,
                          height: isMobile ? 130 : 150,
                          decoration: BoxDecoration(
                            color: _bgCard,
                            borderRadius: BorderRadius.circular(1),
                            border: Border.all(color: _divider),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Icon container
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                      color: _goldBorder.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(1)),
                                  child: Icon(item.icon, color: _gold, size: 22),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title,
                                        style: const TextStyle(
                                            color: _textDark,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(item.subtitle,
                                        style: const TextStyle(
                                            color: _textMuted, fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // ── Logout Button ─────────────────────────────────────
                  Row(children: [
                    Container(width: 3, height: 16,
                        decoration: BoxDecoration(color: _red,
                            borderRadius: BorderRadius.circular(1))),
                    const SizedBox(width: 8),
                    const Text('Account',
                        style: TextStyle(color: _textDark,
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ]),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => LoginPage())),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(1),
                        border: Border.all(color: _divider),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(1)),
                          child: const Icon(Icons.logout_rounded,
                              color: _red, size: 18),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Logout',
                                  style: TextStyle(color: _red,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text('Sign out of admin panel',
                                  style: TextStyle(color: _textMuted,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: _textMuted, size: 14),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Footer ───────────────────────────────────────────
                  Center(
                    child: Text('© 2026 Jewellery Admin • All rights reserved',
                        style: const TextStyle(
                            color: _textMuted, fontSize: 12)),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final int index;
  const _MenuItem(this.icon, this.title, this.subtitle, this.index);
}