import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emregalerimobile/services/api.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveLoginData(String token, List<String> roles) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanToken = token.replaceAll('"', '');
    await prefs.setString('jwt_token', cleanToken);
    await prefs.setString('user_roles', roles.join(','));
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Email ve şifre boş bırakılamaz.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/auth/login');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenRaw = data['token'] as String;
        final rolesFromApi = data['roles'] as List<dynamic>;
        final roles = rolesFromApi.map((e) => e.toString()).toList();

        await _saveLoginData(tokenRaw, roles);

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarılı!')),
        );

        setState(() => _isLoading = false);

        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        String mesaj = 'Giriş başarısız.';
        try {
          final data = jsonDecode(response.body);
          mesaj = data['message'] ?? mesaj;
        } catch (_) {}
        setState(() {
          _isLoading = false;
          _errorMessage = mesaj;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIconColor: Colors.blue.shade700,
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Giriş Yap'),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        elevation: 5,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200.withOpacity(0.6),
                      spreadRadius: 4,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: const Icon(Icons.directions_car, size: 90, color: Colors.blue),
              ).animate().fade(duration: 600.ms).slideY(begin: -0.3),

              const SizedBox(height: 20),

              // Başlık
              Text(
                'Emre Galeri Mobil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade800,
                  letterSpacing: 1.2,
                ),
              ).animate().fade(duration: 600.ms).slideY(begin: -0.2),

              const SizedBox(height: 36),

              // Email
              TextField(
                controller: _emailController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ).animate().fade(duration: 400.ms).slideX(begin: -0.3),

              const SizedBox(height: 22),

              // Şifre
              TextField(
                controller: _passwordController,
                decoration: inputDecoration.copyWith(
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
              ).animate().fade(duration: 400.ms).slideX(begin: 0.3),

              const SizedBox(height: 28),

              // Hata mesajı
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ).animate().fade(duration: 300.ms),

              if (_errorMessage != null) const SizedBox(height: 18),

              // Giriş butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Giriş Yap'),
                ),
              ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 16),

              // Alt linkler
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hesabın yok mu?'),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text('Kayıt Ol'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text("Şifremi Unuttum?"),
                  ),
                ],
              ).animate().fade(duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
