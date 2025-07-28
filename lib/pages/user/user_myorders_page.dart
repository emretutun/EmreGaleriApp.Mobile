// ignore_for_file: deprecated_member_use

import 'package:emregalerimobile/pages/user/user_add_review_page.dart';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:emregalerimobile/models/order.dart';
import 'package:emregalerimobile/services/order_service.dart';
import 'package:intl/intl.dart';

class UserMyOrdersPage extends StatefulWidget {
  const UserMyOrdersPage({super.key});

  @override
  State<UserMyOrdersPage> createState() => _UserMyOrdersPageState();
}

class _UserMyOrdersPageState extends State<UserMyOrdersPage> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = OrderService().fetchMyOrders();
  }

  String formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Widget buildStatusBadge(String status) {
    Color bgColor;
    String text = status;

    switch (status.toLowerCase()) {
      case "reddedildi":
        bgColor = Colors.red.shade600;
        text = "Reddedildi";
        break;
      case "beklemede":
        bgColor = Colors.grey.shade600;
        text = "Beklemede";
        break;
      case "onaylandı":
      case "onaylandi":
        bgColor = Colors.green.shade600;
        text = "Onaylandı";
        break;
      default:
        bgColor = Colors.grey.shade400;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget buildDeliveryStatusBadge(int status) {
    Color bgColor;
    String text;

    switch (status) {
      case 0:
        bgColor = Colors.blueGrey.shade400;
        text = "Kullanımda";
        break;
      case 1:
        bgColor = Colors.green.shade600;
        text = "Teslim Etti";
        break;
      case 2:
        bgColor = Colors.red.shade600;
        text = "Teslim Etmedi";
        break;
      default:
        bgColor = Colors.grey.shade400;
        text = "Bilinmiyor";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget buildCarListTile(OrderItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            "${ApiService.baseUrl}${item.imageUrl}",
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.directions_car_outlined, size: 70, color: Colors.grey),
          ),
        ),
        title: Text(
          "${item.brand} ${item.model}",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          "Araç ID: ${item.carId}",
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Siparişlerim"),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.blue.shade700,
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "Henüz bir siparişiniz yok.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                shadowColor: Colors.blue.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık ve durum
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Sipariş No: ${order.id}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          buildStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Tarihler
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
                          const SizedBox(width: 6),
                          Text(
                            "${formatDate(order.startDate)} - ${formatDate(order.endDate)}",
                            style: const TextStyle(fontSize: 15, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Teslim durumu (sadece reddedilmemiş siparişlerde)
                      if (order.status.toLowerCase() != "reddedildi") ...[
                        Row(
                          children: [
                            const Icon(Icons.delivery_dining, size: 20, color: Colors.blueGrey),
                            const SizedBox(width: 6),
                            const Text(
                              "Teslim Durumu: ",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            buildDeliveryStatusBadge(order.deliveryStatus),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Toplam tutar
                      Text(
                        "Toplam Tutar: ₺${order.totalPrice.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Araçlar
                      ...order.items.map(buildCarListTile),

                      const SizedBox(height: 12),

                      // Yorum Yap butonu sadece uygun siparişlerde göster
                      if (order.status.toLowerCase() != "reddedildi" && order.deliveryStatus != 2)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.rate_review),
                          label: const Text("Yorum Yap"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 130, 186, 241),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddReviewPage(order: order),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
