// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/pages/user/user_car_detail_page.dart';
import 'package:emregalerimobile/pages/user/user_cart_page.dart';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:emregalerimobile/services/card_service.dart';

class UserCarListPage extends StatefulWidget {
  final String token;
  const UserCarListPage({super.key, required this.token});

  @override
  State<UserCarListPage> createState() => _UserCarListPageState();
}

class _UserCarListPageState extends State<UserCarListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> allCars = [];
  List<dynamic> availableCars = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAllCars();
    fetchAvailableCars();
  }

  Future<void> fetchAllCars() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/usercars'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        allCars = jsonDecode(response.body);
      });
    } else {
      debugPrint("Tüm araçları getirirken hata: ${response.statusCode}");
    }
  }

  Future<void> fetchAvailableCars() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/usercars/available'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        availableCars = jsonDecode(response.body);
      });
    } else {
      debugPrint("Müsait araçları getirirken hata: ${response.statusCode}");
    }
  }

  Widget buildCarCard(dynamic car, {bool showAddButton = false}) {
    final baseUrl = ApiService.baseUrl.endsWith('/')
        ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
        : ApiService.baseUrl;
    final imageUrl = car['imageUrl'] != null ? '$baseUrl${car['imageUrl']}' : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserCarDetailPage(token: widget.token, carId: car['id']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: Colors.white,
        shadowColor: Colors.black12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                        );
                      },
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text("Görsel yok")),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${car['brand']} ${car['model']}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2A38), // koyu lacivert
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _iconText(Icons.calendar_today, car['modelYear'].toString()),
                      const SizedBox(width: 20),
                      _iconText(Icons.settings, car['gearType']),
                      const SizedBox(width: 20),
                      _iconText(Icons.local_gas_station, car['fuelType']),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${car['dailyPrice']}₺ / gün",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFFFF6F00), // turuncu vurgu
                    ),
                  ),
                  if (showAddButton)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6F00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            elevation: 3,
                          ),
                          onPressed: () async {
                            await CartService().loadCart();
                            final cartItem = CartItem(
                              carId: car['id'],
                              carName: "${car['brand']} ${car['model']}",
                              dailyPrice: (car['dailyPrice'] as num).toDouble(),
                              imageUrl: imageUrl ?? '',
                            );
                            await CartService().addItem(cartItem);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${cartItem.carName} sepete eklendi!"),
                                backgroundColor: const Color(0xFFFF6F00),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text("Sepete Ekle"),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1E2A38)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 86, 159, 243),
        title: const Text("Araçlar"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Sepetim',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF6F00),
          labelColor: const Color(0xFFFF6F00),
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 4,
          tabs: const [
            Tab(text: "Tüm Araçlar"),
            Tab(text: "Müsait Araçlar"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: fetchAllCars,
            child: allCars.isEmpty
                ? const Center(child: Text('Araç bulunamadı'))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: allCars.length,
                    itemBuilder: (context, index) => buildCarCard(allCars[index]),
                  ),
          ),
          RefreshIndicator(
            onRefresh: fetchAvailableCars,
            child: availableCars.isEmpty
                ? const Center(child: Text('Müsait araç bulunamadı'))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: availableCars.length,
                    itemBuilder: (context, index) =>
                        buildCarCard(availableCars[index], showAddButton: true),
                  ),
          ),
        ],
      ),
    );
  }
}
