import 'package:emregalerimobile/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

    final url = Uri.parse('${ApiService.baseUrl}/api/forgotpasswordapi'); // API adresini kendi sunucuna göre güncelle
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
        _message = data['message'] ?? "Şifre sıfırlama linki mailinize gönderildi.";
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
      appBar: AppBar(title: const Text("Şifremi Unuttum")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "E-posta",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _sendForgotPassword,
                    child: const Text("Gönder"),
                  ),
            if (_message != null) ...[
              const SizedBox(height: 20),
              Text(
                _message!,
                style: TextStyle(
                    color: _message!.toLowerCase().contains("hata") ? Colors.red : Colors.green),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
