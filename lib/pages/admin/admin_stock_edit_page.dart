// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:emregalerimobile/models/stock_item_model.dart';



class AdminStockEditPage extends StatefulWidget {
  final StockItem stockItem;

  const AdminStockEditPage({super.key, required this.stockItem});

  @override
  State<AdminStockEditPage> createState() => _AdminStockEditPageState();
}

class _AdminStockEditPageState extends State<AdminStockEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _productNameController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _quantityController;

  List<Map<String, dynamic>> _firms = [];
  int? _selectedFirmId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.stockItem.productName);
    _purchasePriceController = TextEditingController(text: widget.stockItem.purchasePrice.toString());
    _salePriceController = TextEditingController(text: widget.stockItem.salePrice.toString());
    _quantityController = TextEditingController(text: widget.stockItem.quantity.toString());
    _selectedFirmId = widget.stockItem.firm?.id;

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
      "id": widget.stockItem.id,
      "productName": _productNameController.text.trim(),
      "purchasePrice": double.parse(_purchasePriceController.text),
      "salePrice": double.parse(_salePriceController.text),
      "quantity": int.parse(_quantityController.text),
      "firmId": _selectedFirmId,
    });

    setState(() => _isLoading = true);

    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/api/StockItemApi/${widget.stockItem.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 204) {
      Navigator.pop(context, true);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Hata"),
          content: Text("Stok güncellenemedi: ${response.body}"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tamam"))
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stok Düzenle"),
        backgroundColor: Colors.indigo.shade700,
        centerTitle: true,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _productNameController,
                      decoration: const InputDecoration(labelText: "Ürün Adı"),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Zorunlu alan" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _purchasePriceController,
                      decoration: const InputDecoration(labelText: "Alış Fiyatı"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Zorunlu alan" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _salePriceController,
                      decoration: const InputDecoration(labelText: "Satış Fiyatı"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Zorunlu alan" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: "Adet"),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? "Zorunlu alan" : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: "Firma Seçiniz"),
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
                      validator: (value) =>
                          value == null ? "Lütfen firma seçiniz" : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Güncelle"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
