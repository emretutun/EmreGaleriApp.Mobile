// ignore_for_file: use_build_context_synchronously
import 'package:emregalerimobile/pages/user/user_myorders_page.dart';
import 'package:emregalerimobile/pages/user/user_profile.dart';
import 'package:emregalerimobile/pages/user/user_edit_profile.dart';
import 'package:emregalerimobile/pages/user/user_car_list_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'admin_panel_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isAdminOrYetkili = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final rolesString = prefs.getString('user_roles') ?? '';
    final roles = rolesString.split(',');

    setState(() {
      _isAdminOrYetkili = roles.contains('Yonetici') || roles.contains('Yetkili');
      _isLoading = false;
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    debugPrint('DEBUG: Token alındı: $token');
    return token;
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }


  void _goToUserProfile() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _logout();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(token: token),
      ),
    );
  }

  void _goToUserEditProfile() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _logout();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserEditProfilePage(token: token),
      ),
    );
  }

  void _goToCarList() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _logout();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserCarListPage(token: token),
      ),
    );
  }

  void _goToMyOrders() async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      await _logout();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserMyOrdersPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Emre Galeri',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade800,
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isAdminOrYetkili)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Yönetim Paneli',
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'orders') {
                _goToMyOrders();
              } else if (value == 'profile') {
                _goToUserProfile();
              } else if (value == 'edit_profile') {
                _goToUserEditProfile();
              } else if (value == 'logout') {
                await _logout();
              }
            },
            icon: const Icon(Icons.account_circle_rounded),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'orders',
                child: Text('Siparişlerim'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: Text('Profilim'),
              ),
              const PopupMenuItem(
                value: 'edit_profile',
                child: Text('Profilimi Düzenle'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'change_password',
                child: Text('Şifre Değiştir'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Çıkış Yap'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade400, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.shade200.withOpacity(0.5),
                      spreadRadius: 4,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(30),
                child: const Icon(Icons.directions_car_filled_rounded,
                    size: 90, color: Colors.white),
              ),
              const SizedBox(height: 30),
              Text(
                'Hoş geldin!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Araç kiralama sistemine başarıyla giriş yaptınız.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _goToCarList,
                icon: const Icon(
                  Icons.directions_car,
                  color: Colors.white,
                ),
                label: const Text('Araçları Görüntüle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
