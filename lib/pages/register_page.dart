import 'dart:convert';
import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade700),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Icon(Icons.person_add_alt_1_rounded,
                      size: 80, color: Colors.blue.shade700)
                  .animate()
                  .fade()
                  .scale(duration: 500.ms),
              const SizedBox(height: 20),
              Text(
                'Yeni Hesap Oluştur',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900),
              ).animate().fade().slideY(begin: 0.2, duration: 500.ms),
              const SizedBox(height: 30),
              TextFormField(
                controller: _usernameController,
                decoration: _inputDecoration('Kullanıcı Adı', Icons.person),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Kullanıcı adı boş olamaz' : null,
              ).animate().fade(delay: 100.ms),
              const SizedBox(height: 18),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('E-posta', Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'E-posta boş olamaz';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Geçerli e-posta girin';
                  }
                  return null;
                },
              ).animate().fade(delay: 150.ms),
              const SizedBox(height: 18),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration('Telefon Numarası', Icons.phone),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TurkishPhoneNumberFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Telefon boş olamaz';
                  if (!RegExp(r'^0 \d{3} \d{3} \d{4}$').hasMatch(value)) {
                    return '0 555 555 5555 formatında girin';
                  }
                  return null;
                },
              ).animate().fade(delay: 200.ms),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration('Şifre', Icons.lock),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Şifre boş olamaz';
                  if (value.length < 6) return 'Şifre en az 6 karakter';
                  return null;
                },
              ).animate().fade(delay: 250.ms),
              const SizedBox(height: 18),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: _inputDecoration('Şifre Tekrar', Icons.lock_outline),
                obscureText: true,
                validator: (value) => value != _passwordController.text
                    ? 'Şifreler uyuşmuyor'
                    : null,
              ).animate().fade(delay: 300.ms),
              const SizedBox(height: 30),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ).animate().fade(duration: 500.ms),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Kayıt Ol',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ).animate().fade().slideY(begin: 0.3, delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
