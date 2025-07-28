// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';

import 'package:emregalerimobile/pages/admin/admin_cash_add_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminCashListPage extends StatefulWidget {
  const AdminCashListPage({super.key});

  @override
  State<AdminCashListPage> createState() => _AdminCashListPageState();
}

class _AdminCashListPageState extends State<AdminCashListPage> {
  List<dynamic> transactions = [];
  double balance = 0.0;
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    loadTokenAndFetch();
  }

  Future<void> loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
    if (token == null) {
      _showErrorDialog("Giriş yapmanız gerekiyor.");
      return;
    }
    await fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/cashregisterapi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          transactions = data['transactions'];
          balance = data['balance'].toDouble();
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        _showErrorDialog("Yetkisiz erişim. Lütfen tekrar giriş yapın.");
      } else {
        _showErrorDialog('Veri alınamadı. Kod: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Bir hata oluştu: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteTransaction(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/api/cashregisterapi/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem silindi')),
      );
      await fetchTransactions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silme işlemi başarısız')),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hata"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: const Text('Bu işlemi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kasa Hareketleri"),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Toplam Bakiye:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${balance.toStringAsFixed(2)} ₺",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      final isGider = item['type'] == 'Gider';
                      final String createdBy = item['createdByUserName'] ?? 'Bilinmiyor';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            isGider ? Icons.remove_circle : Icons.add_circle,
                            color: isGider ? Colors.red : Colors.green,
                          ),
                          title: Text(item['description'] ?? 'Açıklama yok'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tarih: ${item['createdAt']}"),
                              Text("Yapan: $createdBy", style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${item['amount']} ₺",
                                style: TextStyle(
                                  color: isGider ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.grey),
                                onPressed: () async {
                                  final confirmed = await _showDeleteConfirmation();
                                  if (confirmed == true) {
                                    await deleteTransaction(item['id']);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminCashAddPage()),
          );
          if (result == true) {
            setState(() {
              isLoading = true;
            });
            await fetchTransactions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
