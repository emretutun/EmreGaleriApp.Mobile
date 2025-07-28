// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/firm_model.dart';
import 'admin_firm_add_page.dart'; // Yeni firma ekleme sayfası
import 'admin_firm_edit_page.dart'; // Firma düzenleme sayfası
import 'package:emregalerimobile/services/api.dart'; // ApiService importu

class AdminFirmListPage extends StatefulWidget {
  const AdminFirmListPage({super.key});

  @override
  State<AdminFirmListPage> createState() => _AdminFirmListPageState();
}

class _AdminFirmListPageState extends State<AdminFirmListPage> {
  List<FirmModel> _firms = [];
  bool _isLoading = true;

  // baseUrl kaldırıldı, ApiService.baseUrl kullanılacak

  @override
  void initState() {
    super.initState();
    fetchFirms();
  }

  Future<void> fetchFirms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      debugPrint('Token bulunamadı veya boş');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/FirmApi'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        setState(() {
          _firms = data.map((e) => FirmModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        debugPrint('Firma verisi alınamadı: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Hata oluştu: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> deleteFirm(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      debugPrint('Token bulunamadı veya boş');
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/api/FirmApi/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        setState(() {
          _firms.removeWhere((element) => element.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firma başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        debugPrint('Silinemedi: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firma silinemedi! Hata kodu: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Silme sırasında hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFirmCard(FirmModel firm) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: Colors.indigo.shade100,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.indigo.shade100,
              child: Text(
                firm.name.isNotEmpty ? firm.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firm.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (firm.contactPerson.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            firm.contactPerson,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (firm.phone.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          firm.phone,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  if (firm.email.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            firm.email,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Düzenle',
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminFirmEditPage(firm: firm),
                      ),
                    );
                    if (result == true) {
                      fetchFirms();
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Sil',
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Silme Onayı'),
                        content: const Text('Firmayı silmek istediğinize emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              deleteFirm(firm.id);
                            },
                            child: const Text(
                              'Sil',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firmalar'),
        backgroundColor: Colors.indigo.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            color: Colors.white,
            onPressed: fetchFirms,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Firma Ekle',
            color: Colors.white,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminFirmAddPage()),
              );
              if (result == true) {
                fetchFirms();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _firms.isEmpty
              ? Center(
                  child: Text(
                    'Hiç firma bulunamadı.',
                    style: theme.textTheme.titleMedium,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchFirms,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _firms.length,
                    itemBuilder: (context, index) => _buildFirmCard(_firms[index]),
                  ),
                ),
    );
  }
}
