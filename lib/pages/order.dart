import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List orders = [];
  bool loading = true;

  final String baseUrl =
      "https://jewellery-backend-icja.onrender.com/api/checkout";

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final res = await http.get(Uri.parse(baseUrl));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          orders = data["orders"] ?? [];
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  String getCustomerName(dynamic address) {
    if (address is Map && address["name"] != null) {
      return address["name"];
    }
    return "Customer";
  }

  String getAddressText(dynamic address) {
    if (address is Map) {
      return "${address["street"]}, ${address["city"]}";
    }
    if (address is String) {
      return address;
    }
    return "";
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "delivered":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "placed":
        return Colors.blue;
      case "return accepted":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),

            if (loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (orders.isEmpty)
              const Expanded(
                child: Center(child: Text("No Orders Found")),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final address = order["address"];
                    final status = order["status"] ?? "pending";

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// LEFT INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Order ID: ${order["_id"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    getCustomerName(address),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    getAddressText(address),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Items: ${order["items"]?.length ?? 0}",
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "₹ ${order["totalAmount"]}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// RIGHT STATUS
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor(status)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  order["paymentMethod"]
                                      ?.toString()
                                      .toUpperCase() ??
                                      "",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}