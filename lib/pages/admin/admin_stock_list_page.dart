// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/models/stock_item_model.dart';
import 'package:emregalerimobile/pages/admin/admin_stock_add_page.dart';
import 'package:emregalerimobile/pages/admin/admin_stock_edit_page.dart';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Sadece domain ve porttan oluşan baseUrl


class AdminStockListPage extends StatefulWidget {
  const AdminStockListPage({super.key});

  @override
  State<AdminStockListPage> createState() => _AdminStockListPageState();
}

class _AdminStockListPageState extends State<AdminStockListPage> {
  List<StockItem> _stockList = [];
  bool _isLoading = true;

  Future<void> fetchStockItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    if (token.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final response = await http.get(
      // API endpoint tam yol olarak eklenmeli
      Uri.parse('${ApiService.baseUrl}/api/StockItemApi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      setState(() {
        _stockList = jsonData.map((e) => StockItem.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stok verisi alınamadı: ${response.statusCode}")),
      );
    }
  }

  Future<void> deleteStock(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yetkisiz işlem: Giriş yapmanız gerekiyor.')),
      );
      return;
    }

    final response = await http.delete(
      // Silme için endpoint tam yol olacak şekilde
      Uri.parse('${ApiService.baseUrl}s/api/StockItemApi/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stok başarıyla silindi")),
      );
      await fetchStockItems();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme hatası: ${response.statusCode} - ${response.body}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStockItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stok Listesi"),
        backgroundColor: Colors.indigo.shade700,
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            color: Colors.white,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminStockAddPage()),
              );
              await fetchStockItems();
            },
            tooltip: "Yeni Stok Ekle",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stockList.isEmpty
              ? const Center(
                  child: Text(
                    "Stok bulunamadı.",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  itemCount: _stockList.length,
                  itemBuilder: (context, index) {
                    final item = _stockList[index];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        title: Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        subtitle: Text(
                          "Adet: ${item.quantity} | Satış: ₺${item.salePrice.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              tooltip: "Düzenle",
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminStockEditPage(stockItem: item),
                                  ),
                                );
                                await fetchStockItems();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Sil",
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Onay'),
                                    // ignore: unnecessary_string_escapes
                                    content: Text('\"${item.productName}\" stok kaydını silmek istediğinize emin misiniz?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await deleteStock(item.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
