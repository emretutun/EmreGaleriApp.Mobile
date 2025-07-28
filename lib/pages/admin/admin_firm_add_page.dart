// ignore_for_file: use_build_context_synchronously

import 'package:emregalerimobile/services/api.dart';  // İstediğin import burası
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

import '../../models/firm_model.dart';

// Telefon numarası için Türk formatlayıcı
class TurkishPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 11; i++) {
      formatted += digits[i];
      if (i == 0 || i == 3 || i == 6) {
        if (i != digits.length - 1) formatted += ' ';
      }
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AdminFirmAddPage extends StatefulWidget {
  const AdminFirmAddPage({super.key});

  @override
  State<AdminFirmAddPage> createState() => _AdminFirmAddPageState();
}

class _AdminFirmAddPageState extends State<AdminFirmAddPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.indigo.shade700, width: 2)),
      labelStyle: TextStyle(color: Colors.grey.shade800),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş yapılmamış veya token bulunamadı')),
      );
      return;
    }

    FirmModel newFirm = FirmModel(
      id: 0,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/FirmApi'),  // Burada baseUrl Api sınıfından
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(newFirm.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firma başarıyla eklendi')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firma eklenemedi: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Firma Ekle'),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      'Firma Bilgileri',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Firma Adı *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Firma adı zorunludur';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration('Adres'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPersonController,
                      decoration: _inputDecoration('Yetkili Kişi'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration('Telefon'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TurkishPhoneNumberFormatter(),
                      ],
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^0 \d{3} \d{3} \d{4}$').hasMatch(value)) {
                            return '0 555 555 5555 formatında girin';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('E-posta'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!regex.hasMatch(value)) {
                            return 'Geçerli bir e-posta giriniz';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: _inputDecoration('Notlar'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Kaydet', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
