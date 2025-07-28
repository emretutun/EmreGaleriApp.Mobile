// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminOrderListPage extends StatefulWidget {
  final String token;

  // ignore: use_super_parameters
  const AdminOrderListPage({required this.token, Key? key}) : super(key: key);

  @override
  State<AdminOrderListPage> createState() => _AdminOrderListPageState();
}

class _AdminOrderListPageState extends State<AdminOrderListPage> with SingleTickerProviderStateMixin {
  List<dynamic> orders = [];
  List<dynamic> filteredOrders = [];
  List<dynamic> undeliveredOrders = [];
  bool isLoading = true;

  

  final List<String> statusOptions = ['Hepsi', 'Beklemede', 'Onaylandı', 'Reddedildi', 'Tamamlandı'];
  String selectedStatus = 'Hepsi';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
    });

    print("Kullanılan token: ${widget.token}");  // Token kontrol için yazdırıldı

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/orderapi'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final allOrders = json.decode(response.body);
      setState(() {
        orders = allOrders;
        _applyFilter();
        _filterUndelivered();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Siparişler alınamadı: ${response.statusCode}")),
      );
    }
  }

  void _applyFilter() {
    setState(() {
      if (selectedStatus == 'Hepsi') {
        filteredOrders = orders;
      } else {
        filteredOrders = orders.where((order) {
          return order["status"] == selectedStatus;
        }).toList();
      }
    });
  }

  void _filterUndelivered() {
    setState(() {
      undeliveredOrders = orders.where((order) {
        var delivery = order["deliveryStatus"];
        return order["status"] == "Tamamlandı" &&
            (delivery == null || delivery == 0 || delivery == "NotDelivered");
      }).toList();
    });
  }

  Future<void> updateOrderStatus(int orderId, bool approve) async {
    final url = '${ApiService.baseUrl}/api/orderapi/$orderId/${approve ? "approve" : "reject"}';

    print("updateOrderStatus için token: ${widget.token}");

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? "Sipariş onaylandı" : "Sipariş reddedildi")),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("İşlem başarısız: ${response.statusCode}")),
      );
    }
  }

  Future<void> setDeliveryStatus(int orderId, String status) async {
    final url = Uri.parse("${ApiService.baseUrl}/api/orderapi/set-delivery-status?orderId=$orderId&status=$status");

    print("setDeliveryStatus için token: ${widget.token}");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Teslim durumu güncellendi.")),
      );
      fetchOrders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: ${response.body}")),
      );
    }
  }

  Color _getCardColor(String status) {
    switch (status) {
      case 'Beklemede':
        return Colors.amber.shade100;
      case 'Onaylandı':
      case 'Tamamlandı':
        return Colors.green.shade100;
      case 'Reddedildi':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Widget _buildOrderCard(dynamic order, {bool showDeliveryButtons = true}) {
    final cars = order["cars"] as List<dynamic>? ?? [];
    final carNames = cars.map((c) => "${c['brand']} ${c['model']}").join(", ");

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      color: _getCardColor(order["status"] ?? ''),
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(carNames,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
            const SizedBox(height: 8),
            Text("Kullanıcı: ${order["userName"]}", style: const TextStyle(fontSize: 14)),
            Text("Tarih: ${order["startDate"]} - ${order["endDate"]}", style: const TextStyle(fontSize: 14)),
            Text("Toplam: ${order["totalPrice"]} ₺", style: const TextStyle(fontSize: 14)),
            if (order["description"] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text("Açıklama: ${order["description"]}",
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
              ),
            const SizedBox(height: 14),

            if (showDeliveryButtons) ...[
              if (order["status"] == "Beklemede")
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => updateOrderStatus(order["id"], true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Onayla"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => updateOrderStatus(order["id"], false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Reddet"),
                    ),
                  ],
                ),

              if (order["status"] == "Tamamlandı" &&
                  (order["deliveryStatus"] == null || order["deliveryStatus"] == 0))
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => setDeliveryStatus(order["id"], "Delivered"),
                      icon: const Icon(Icons.check),
                      label: const Text("Teslim Etti"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => setDeliveryStatus(order["id"], "NotDelivered"),
                      icon: const Icon(Icons.close),
                      label: const Text("Teslim Etmedi"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("Siparişler"),
          centerTitle: true,
          backgroundColor: Colors.indigo.shade700,
          elevation: 3,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black,
            tabs: const [
              Tab(text: "Siparişler"),
              Tab(text: "Teslimat Durumu"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // 1. Tab: Tüm Siparişler + Filtre
            Column(
              children: [
                Container(
                  color: Colors.indigo.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.indigo),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedStatus,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: statusOptions.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status, style: const TextStyle(color: Colors.indigo)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedStatus = value;
                                _applyFilter();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredOrders.isEmpty
                          ? const Center(
                              child: Text(
                                "Filtreye uygun sipariş bulunamadı.",
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                return _buildOrderCard(order);
                              },
                            ),
                ),
              ],
            ),

            // 2. Tab: Teslim Edilmemiş Siparişler
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : undeliveredOrders.isEmpty
                    ? const Center(
                        child: Text(
                          "Teslim edilmemiş sipariş bulunamadı.",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: undeliveredOrders.length,
                        itemBuilder: (context, index) {
                          final order = undeliveredOrders[index];
                          return _buildOrderCard(order, showDeliveryButtons: true);
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
