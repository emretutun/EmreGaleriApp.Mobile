import 'package:emregalerimobile/pages/admin/admin_car_list_page.dart';
import 'package:emregalerimobile/pages/admin/admin_order_list_page.dart';
import 'package:emregalerimobile/pages/admin/admin_role_list_page.dart';
import 'package:emregalerimobile/pages/admin/admin_user_list_page.dart';
import 'package:emregalerimobile/pages/admin/admin_personel.dart';
import 'package:emregalerimobile/pages/admin/admin_firm_list.dart';
import 'package:emregalerimobile/pages/admin/admin_stock_list_page.dart';
import 'package:emregalerimobile/pages/admin/admin_cash_list_page.dart';
import 'package:emregalerimobile/pages/admin/admin_reminder_page.dart'; // Hatırlatmalar sayfası
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  String? token;
  List<String> roles = [];

  @override
  void initState() {
    super.initState();
    _loadTokenAndRoles();
  }

  Future<void> _loadTokenAndRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('jwt_token');
    final storedRoles = prefs.getString('user_roles') ?? '';

    setState(() {
      token = storedToken;
      roles = storedRoles.split(',');
    });
  }

  void _showUnauthorizedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bu sayfaya erişim yetkiniz yok."),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.indigo.shade200,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: Colors.indigo.shade100,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          width: double.infinity,
          child: Row(
            children: [
              Icon(icon, size: 32, color: Colors.indigo.shade700),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.indigo.shade900,
                      ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.indigo.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Yönetim Paneli'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade700,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.note),
            color: const Color.fromARGB(255, 237, 80, 37),
            tooltip: 'Hatırlatmalar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminReminderPage(token: token!),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMenuCard(
                  context,
                  title: 'Tüm Araçları Görüntüle',
                  icon: Icons.directions_car,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminCarListPage(token: token!),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  title: 'Siparişleri Yönet',
                  icon: Icons.list_alt,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminOrderListPage(token: token!),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  title: 'Rolleri Yönet',
                  icon: Icons.admin_panel_settings,
                  onTap: () {
                    if (roles.contains("Yonetici")) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminRoleListPage(),
                        ),
                      );
                    } else {
                      _showUnauthorizedMessage();
                    }
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  title: 'Kullanıcıları Görüntüle',
                  icon: Icons.people,
                  onTap: () {
                    if (roles.contains("Yonetici") || roles.contains("Yetkili")) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminUserListPage(),
                        ),
                      );
                    } else {
                      _showUnauthorizedMessage();
                    }
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  title: 'Personel Yönetimi',
                  icon: Icons.badge,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPersonelPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  title: 'Firma Yönetimi',
                  icon: Icons.business,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminFirmListPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  title: 'Stokları Yönet',
                  icon: Icons.inventory_2,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminStockListPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  context,
                  title: 'Kasa Yönetimi',
                  icon: Icons.attach_money,
                  onTap: () {
                    if (roles.contains("Yonetici")) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminCashListPage(),
                        ),
                      );
                    } else {
                      _showUnauthorizedMessage();
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
