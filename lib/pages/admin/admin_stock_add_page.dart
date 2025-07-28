// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class AdminStockAddPage extends StatefulWidget {
  const AdminStockAddPage({super.key});

  @override
  State<AdminStockAddPage> createState() => _AdminStockAddPageState();
}

class _AdminStockAddPageState extends State<AdminStockAddPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  List<Map<String, dynamic>> _firms = [];
  int? _selectedFirmId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchFirms();
  }

  Future<void> _fetchFirms() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/api/FirmApi'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      setState(() {
        _firms = decoded.cast<Map<String, dynamic>>();
      });
    } else {
      debugPrint("Firma getirme hatası: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firma bilgileri alınamadı.')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final body = jsonEncode({
      "productName": _productNameController.text.trim(),
      "purchasePrice": double.parse(_purchasePriceController.text),
      "salePrice": double.parse(_salePriceController.text),
      "quantity": int.parse(_quantityController.text),
      "firmId": _selectedFirmId,
    });

    setState(() => _isLoading = true);

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/api/StockItemApi'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Hata"),
          content: Text("Stok eklenemedi: ${response.body}"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tamam"))
          ],
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Stok Ekle"),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.indigo.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _productNameController,
                      decoration: _inputDecoration("Ürün Adı"),
                      validator: (value) => value == null || value.isEmpty ? "Zorunlu alan" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _purchasePriceController,
                      decoration: _inputDecoration("Alış Fiyatı"),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? "Zorunlu alan" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _salePriceController,
                      decoration: _inputDecoration("Satış Fiyatı"),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? "Zorunlu alan" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: _inputDecoration("Adet"),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? "Zorunlu alan" : null,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<int>(
                      decoration: _inputDecoration("Firma Seçiniz").copyWith(
                        prefixIcon: const Icon(Icons.business),
                      ),
                      value: _selectedFirmId,
                      items: _firms
                          .map(
                            (firm) => DropdownMenuItem<int>(
                              value: firm['id'],
                              child: Text(firm['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selectedFirmId = value),
                      validator: (value) => value == null ? "Lütfen firma seçiniz" : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          elevation: 3,
                        ),
                        child: const Text("Kaydet"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
