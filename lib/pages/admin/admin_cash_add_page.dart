// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class AdminCashAddPage extends StatefulWidget {
  const AdminCashAddPage({super.key});

  @override
  State<AdminCashAddPage> createState() => _AdminCashAddPageState();
}

class _AdminCashAddPageState extends State<AdminCashAddPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'Gelir';

  Future<void> _addTransaction() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapmanız gerekiyor!')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/cashregisterapi'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': double.tryParse(_amountController.text) ?? 0,
        'type': _selectedType,
        'description': _descriptionController.text,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem eklenemedi: ${response.statusCode}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Para Girişi / Çıkışı')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'İşlem Türü'),
              items: const [
                DropdownMenuItem(value: 'Gelir', child: Text('Gelir')),
                DropdownMenuItem(value: 'Gider', child: Text('Gider')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tutar'),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Açıklama'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addTransaction,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
