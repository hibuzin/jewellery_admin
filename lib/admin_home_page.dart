import 'package:flutter/material.dart';
import 'package:jewellery_admin/login.dart';
import 'package:jewellery_admin/pages/advertisement.dart';
import 'package:jewellery_admin/pages/category.dart';
import 'package:jewellery_admin/pages/order.dart';
import 'package:jewellery_admin/pages/product.dart';
import 'package:jewellery_admin/pages/sub_category.dart';
import 'package:jewellery_admin/signup.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    // Titles for each card
    final List<String> cardTitles = [
      'ORDER',
      'CATEGORY',
      'SUB CATEGORY',
      'PRODUCTS',
      'ADVERTISEMENT',
      'ABOUT',
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // ===== Header =====
          Container(
            height: 60,
            width: double.infinity,
            color: Colors.blueGrey,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Admin ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ===== Scrollable content =====
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 40,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ===== Stats Cards =====
                    Wrap(
                      spacing: 20, // horizontal spacing
                      runSpacing: 20, // vertical spacing
                      children: List.generate(6, (index) {
                        double cardWidth = isMobile
                            ? double.infinity
                            : (MediaQuery.of(context).size.width - 120) / 3;

                        // Individual onTap for each card
                        void onCardTap() {
                          switch (index) {
                            case 0:
                              Navigator.push(
                                  context, MaterialPageRoute(builder: (context)=> OrderPage()));
                              break;
                            case 1:
                              Navigator.push(
                                  context, MaterialPageRoute(builder: (context)=> CategoryPage()));
                              break;
                            case 2:
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context)=> SubcategoryPage()));
                              break;
                            case 3:
                              Navigator.push(
                                  context, MaterialPageRoute(builder: (context)=> ProductPage()));
                              break;
                            case 4:
                              Navigator.push(
                                  context, MaterialPageRoute(builder: (context)=> AdvertisementPage()));
                              break;
                            case 5:
                              print("Go to about Page");
                              break;
                          }
                        }

                        return InkWell(
                          onTap: onCardTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: cardWidth,
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cardTitles[index],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 40),

                    // ===== Section 2: Table placeholder =====
                    InkWell(
                      onTap: (){
                        Navigator.push(
                            context, MaterialPageRoute(builder: (context)=> LoginPage()));
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Center(
                              child: Text(
                                'LOGOUT',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ===== Footer =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      color: Colors.blueGrey.shade50,
                      child: const Text(
                        '© 2026 Admin Dashboard | All rights reserved',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}