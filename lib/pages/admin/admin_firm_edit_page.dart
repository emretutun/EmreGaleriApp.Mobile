import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:emregalerimobile/services/api.dart';
import '../../models/firm_model.dart';

class AdminFirmEditPage extends StatefulWidget {
  final FirmModel firm;

  const AdminFirmEditPage({super.key, required this.firm});

  @override
  State<AdminFirmEditPage> createState() => _AdminFirmEditPageState();
}

class _AdminFirmEditPageState extends State<AdminFirmEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.firm.name);
    _addressController = TextEditingController(text: widget.firm.address);
    _contactPersonController = TextEditingController(text: widget.firm.contactPerson);
    _phoneController = TextEditingController(text: widget.firm.phone);
    _emailController = TextEditingController(text: widget.firm.email);
    _notesController = TextEditingController(text: widget.firm.notes);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş yapılmamış veya token bulunamadı')),
        );
      }
      return;
    }

    FirmModel updatedFirm = FirmModel(
      id: widget.firm.id,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      contactPerson: _contactPersonController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      notes: _notesController.text.trim(),
    );

    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/api/FirmApi/${widget.firm.id}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedFirm.toJson()),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Firma başarıyla güncellendi')),
          );
          Navigator.pop(context, true); // Listeyi yenilemek için true döner
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Firma güncellenemedi: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma Düzenle'),
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
                            : const Text('Güncelle', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

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
