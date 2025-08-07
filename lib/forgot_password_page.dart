import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';

import 'package:emregalerimobile/services/api.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _message = "Lütfen e-posta adresinizi girin.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final url = Uri.parse('${ApiService.baseUrl}/api/forgotpasswordapi');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _message =
            data['message'] ?? "Şifre sıfırlama linki mailinize gönderildi.";
      });
    } else {
      setState(() {
        _message = "Bir hata oluştu, lütfen tekrar deneyin.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Şifremi Unuttum"),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 3,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_outline,
                size: 80, color: Colors.blueAccent.shade200)
                .animate()
                .fade(duration: 600.ms)
                .scale(delay: 200.ms),
            const SizedBox(height: 20),
            Text(
              "Şifre Sıfırlama",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
              textAlign: TextAlign.center,
            ).animate().fade().slideY(begin: 0.2, duration: 600.ms),
            const SizedBox(height: 12),
            Text(
              "Kayıtlı e-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.",
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "E-posta adresi",
                hintText: "ornek@eposta.com",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
            ).animate().fade(duration: 500.ms),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                    .animate()
                    .fade()
                : ElevatedButton.icon(
                    onPressed: _sendForgotPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.send),
                    label: const Text(
                      "Gönder",
                      selectionColor: Colors.white,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ).animate().fade(delay: 200.ms).slideX(begin: -0.2),
            const SizedBox(height: 24),
            if (_message != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _message!.toLowerCase().contains("hata")
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _message!.toLowerCase().contains("hata")
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _message!.toLowerCase().contains("hata")
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _message!.toLowerCase().contains("hata")
                              ? Colors.red.shade700
                              : Colors.green.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}
