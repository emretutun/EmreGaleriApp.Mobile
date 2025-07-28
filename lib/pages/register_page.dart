// ... diğer importlar
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

// Base URL burada merkezi olarak tanımlandı


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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Base URL kullanıldı
    final uri = Uri.parse('${ApiService.baseUrl}/api/auth/register');

    final body = {
      "username": _usernameController.text.trim(),
      "email": _emailController.text.trim(),
      "phoneNumber": _phoneController.text.trim(),
      "password": _passwordController.text.trim(),
      "confirmPassword": _confirmPasswordController.text.trim(),
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! Giriş yapabilirsiniz.')),
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Kayıt başarısız oldu.';
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.blue.shade700, width: 2)),
      labelStyle: TextStyle(color: Colors.grey.shade800),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Yeni Hesap Oluştur', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
              const SizedBox(height: 30),
              TextFormField(
                controller: _usernameController,
                decoration: _inputDecoration('Kullanıcı Adı'),
                validator: (value) => (value == null || value.isEmpty) ? 'Kullanıcı adı boş olamaz' : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('E-posta'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'E-posta boş olamaz';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Geçerli e-posta girin';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Telefon Numarası'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TurkishPhoneNumberFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Telefon boş olamaz';
                  if (!RegExp(r'^0 \d{3} \d{3} \d{4}$').hasMatch(value)) return '0 555 555 5555 formatında girin';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration('Şifre'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Şifre boş olamaz';
                  if (value.length < 6) return 'Şifre en az 6 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: _inputDecoration('Şifre Tekrar'),
                obscureText: true,
                validator: (value) => value != _passwordController.text ? 'Şifreler uyuşmuyor' : null,
              ),
              const SizedBox(height: 30),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Kayıt Ol', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
